#!/usr/bin/env python3
"""Deterministic fixed-size gzip/PNG/GPU resource regression tests (2026)."""
import gzip
import hashlib
import json
import sys
from pathlib import Path

from compile_recovered_resources import ROOT, records, rebuild, gzip_fit, CRY_IMAGES, sha


def main():
    layout = json.loads((ROOT/'build/retail_link_data_layout.json').read_text())['entries']
    by_addr = {x['retail_offset']: x for x in layout}
    checked = 0
    png_count=0
    compiled_gpu=0
    for rec in records():
        packed=(ROOT/by_addr[rec['rom_start']]['recovered_asset']).read_bytes()
        encoded,details=rebuild(rec,packed,allow_edits=False)
        assert encoded==packed,rec['label']
        assert not details['changed'],rec['label']
        assert sha(gzip.decompress(encoded))==rec['original_sha256'],rec['label']
        checked+=1
        if rec['rom_start'] in CRY_IMAGES:png_count+=1
        if rec['known_gpu']:compiled_gpu+=1
    sky=next(x for x in records() if x['rom_start']==0x1BF258)
    original=(ROOT/by_addr[sky['rom_start']]['recovered_asset']).read_bytes()
    raw=bytearray(gzip.decompress(original));pos=2*(20*768+100)
    raw[pos]^=1
    compressed,codec,used=gzip_fit(raw,original)
    assert len(compressed)==sky['packed_capacity']
    assert gzip.decompress(compressed)==raw
    assert gzip.decompress(compressed)[pos] != gzip.decompress(original)[pos]
    # A highly incompressible raw icon must be rejected; never permit a write
    # to the neighboring ROM asset. Produce a deterministic high-entropy buffer.
    icon=next(x for x in records() if x['rom_start']==0xEA390)
    icon_original=(ROOT/by_addr[icon['rom_start']]['recovered_asset']).read_bytes()
    stream=b''.join(hashlib.sha256(i.to_bytes(4,'big')).digest() for i in range(512))
    assert len(stream)==icon['raw_size']
    rejected=False
    try:gzip_fit(stream,icon_original)
    except ValueError:rejected=True
    assert rejected,'Oversized gzip resource unexpectedly accepted'
    report={'pass':True,'clean_resources':checked,'source_pngs':png_count,
       'embedded_compiled_world_gpus':compiled_gpu,
       'one_byte_edit_gzip_roundtrip':True,'fixed_slot_overflow_rejected':True,
       'pristine_rom_sha256':'dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289'}
    (ROOT/'build/audio_bank_resource_regression.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
