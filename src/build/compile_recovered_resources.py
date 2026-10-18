#!/usr/bin/env python3
"""Recompile Club Drive's recovered gzip resources without changing ROM layout.

RECONSTRUCTION NOTES (2026; not original Atari comments)
--------------------------------------------------------
The retail game's 22 independently terminated gzip members have known
addresses, lengths and exact uncompressed bytes. These are reliable facts;
no claim is made about the layout of meshes, collision trees or non-CRY art
inside the unpacked world files.

Unmodified resources retain the exact original gzip bitstream. Edited raw
files, verified CRY PNGs, ART.S object data and world-local GPU assembly are
compiled into a new gzip stream. The stream must fit the original member
length; it is followed with zero padding when shorter. It is NEVER shifted
into the next resource. This preserves the original cartridge pointer layout.

A pixel-source PNG is deliberately lossless, not a normal RGB edit source:
R holds the high Jaguar CRY byte, G holds the low byte, and B is ignored.
Preview PNG files are for display only; compiling them would lose CRY data.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RESOURCES = ROOT / 'assets/native/resources/packed'
TABLE = RESOURCES / 'resources.json'

# Dimensions are proven by the original uncompressed resource lengths and
# successful pixel round-trip. Do not invent dimensions for unknown meshes.
CRY_IMAGES = {
    0x1BF258: (768, 120),
    0x1CA550: (768, 120),
    0x1F4380: (320, 60),
    0x1F4BB0: (160, 104),
}
WORLD_GPU_LENGTH = {'gpustud': 514, 'gpugara': 308, 'gpuhouse': 872, 'gpucity': 308}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def records():
    entries = json.loads(TABLE.read_text())['resources']
    if len(entries) != 22 or len({r['rom_start'] for r in entries}) != 22:
        raise ValueError('Expected the 22 separately verified gzip resources')
    return entries


def source_png_bytes(record):
    off = record['rom_start']
    if off not in CRY_IMAGES:
        return None
    w, h = CRY_IMAGES[off]
    # Different historical recovery passes used slightly different naming.
    tag = f'{off:06X}_{record["label"]}'
    path = RESOURCES / f'{tag}.png'
    if not path.is_file():
        raise FileNotFoundError(f'Missing editable CRY image: {path}')
    with Image.open(path) as im:
        if im.mode != 'RGB' or im.size != (w, h):
            raise ValueError(f'{path}: expected RGB {w}x{h}, no palette or alpha conversion')
        pixels = im.tobytes()
    raw = bytes(c for i in range(0, len(pixels), 3) for c in pixels[i:i + 2])
    if len(raw) != record['raw_size']:
        raise ValueError(f'{path}: unexpected decoded byte count')
    return raw


def source_art_bytes(record):
    if record['rom_start'] != 0x54118:
        return None
    path = ROOT / 'build/obj/art.o'
    if not path.exists():
        return None
    obj = path.read_bytes()
    if obj[:4] != bytes.fromhex('00000107'):
        raise ValueError('Invalid ART.S 68000 object header')
    size = struct.unpack_from('>I', obj, 4)[0]
    if size != record['raw_size']:
        raise ValueError('ART.S no longer fits the original unpacked size')
    return obj[32:32 + size]


def compiled_raw(record, *, allow_edits: bool, original_raw: bytes):
    original_path = RESOURCES / record['file']
    raw = original_path.read_bytes()
    if len(raw) != record['raw_size']:
        raise ValueError(f'{original_path.name}: unpacked size changed')
    original_hash = record['original_sha256']
    baseline = sha(raw) == original_hash
    sources = [('raw .bin', raw)]
    png = source_png_bytes(record)
    if png is not None:
        sources.append(('CRY16 .png', png))
    art = source_art_bytes(record)
    if art is not None:
        sources.append(('ART.S', art))
    # Original data has the expected checksum, so a second changed authoring
    # source is unambiguous. Two *different* edits are not: reject conflicts.
    different = [(name, b) for name, b in sources if sha(b) != original_hash]
    if len({sha(b) for _, b in different}) > 1:
        raise ValueError(f'{record["label"]}: conflicting edits in multiple authoring sources')
    if different:
        desc, raw = different[0]
    else:
        desc, raw = 'unchanged original data', sources[0][1]
    gpu_name = record['known_gpu']
    if gpu_name:
        path = ROOT / 'build/gpu' / f'{gpu_name}.bin'
        program = path.read_bytes()
        length = WORLD_GPU_LENGTH[gpu_name]
        off = record['gpu_uncompressed_offset']
        if len(program) != length or off < 0 or off + length > len(raw):
            raise ValueError(f'{gpu_name}: invalid GPU length or world offset')
        # The untouched source world is the authority for byte-for-byte GPU
        # layout. Source GPU edits take precedence unless they conflict with
        # an independently edited world at the same bytes.
        old_gpu = original_raw[off:off + length]
        world_gpu = raw[off:off + length]
        if program != old_gpu and world_gpu != old_gpu and program != world_gpu:
            raise ValueError(f'{gpu_name}: GPU source and world binary edits conflict')
        if program != world_gpu:
            raw = raw[:off] + program + raw[off + length:]
            desc += f' + {gpu_name}.GAS'
    if len(raw) != record['raw_size']:
        raise ValueError(f'{record["label"]}: resource size changed unexpectedly')
    if not allow_edits and sha(raw) != original_hash:
        raise ValueError(f'{record["label"]}: an authoring source differs from retail; use --allow-edited-resources')
    return raw, desc


def gzip_fit(raw: bytes, original_member: bytes):
    capacity = len(original_member)
    original = gzip.decompress(original_member)
    if raw == original:
        return original_member, 'preserved original gzip', capacity
    options = []
    for level in (9, 8, 7, 6, 5, 4, 3, 2, 1):
        options.append((f'gzip level {level}', gzip.compress(raw, compresslevel=level, mtime=0)))
    best = min(options, key=lambda v: len(v[1]))
    if len(best[1]) > capacity:
        try:
            import zopfli.gzip
            encoded = zopfli.gzip.compress(raw, numiterations=15)
            if len(encoded) < len(best[1]):
                best = ('zopfli gzip', encoded)
        except ImportError:
            pass
    label, result = best
    if len(result) > capacity:
        raise ValueError(f'gzip resource cannot fit: need {len(result)}, slot {capacity}; no neighboring resource overwritten')
    if gzip.decompress(result) != raw:
        raise ValueError('Lossless compression round trip failed')
    return result + bytes(capacity - len(result)), label, len(result)


def rebuild(record, original_packed: bytes, *, allow_edits: bool):
    if len(original_packed) != record['packed_capacity']:
        raise ValueError(f'{record["label"]}: incorrect reference compressed size')
    if not original_packed.startswith(b'\x1f\x8b\x08'):
        raise ValueError(f'{record["label"]}: not a gzip member')
    baseline = gzip.decompress(original_packed)
    if sha(baseline) != record['original_sha256']:
        raise ValueError(f'{record["label"]}: packed baseline mismatches inventory')
    raw, origin = compiled_raw(record, allow_edits=allow_edits, original_raw=baseline)
    zipped, method, written = gzip_fit(raw, original_packed)
    if gzip.decompress(zipped) != raw:
        raise ValueError('Repacked data decompression failed')
    return zipped, dict(symbol=record['label'], offset=f'{record["rom_start"]:#x}',
         source=origin, changed=raw != baseline, raw_sha256=sha(raw),
         compression=method, packed_bytes=written,
         original_packed_bytes=record['packed_capacity'])


def inspect():
    data = []
    for record in records():
        data.append({'offset':f'{record["rom_start"]:#x}', 'resource': record['label'],
                     'raw_bytes':record['raw_size'], 'original_gzip_bytes':record['packed_capacity'],
                     'editable_png':record['rom_start'] in CRY_IMAGES,
                     'world_gpu_source':record['known_gpu']})
    return data


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--json', type=Path)
    a = ap.parse_args()
    table = inspect()
    if a.json:
        a.json.write_text(json.dumps(table, indent=2) + '\n')
    for r in table:
        print(f'{r["offset"]:>10} {r["resource"]:<26} raw={r["raw_bytes"]:>7} gzip={r["original_gzip_bytes"]:>7} PNG={r["editable_png"]} GPU={r["world_gpu_source"] or "-"}')


if __name__ == '__main__':
    main()
