#!/usr/bin/env python3
"""Audit all four source-generated world-local GPU kernels in linked .j64.

Unlike a standalone .GAS checksum, this proves the actual source-linked ROM
contains the recompiled kernel *inside the gzip resource loaded at runtime*.
"""
from pathlib import Path
import argparse,hashlib,json,re,zlib,sys
from link_recovered_stage import load_rom,ROOT,GPU_LABELS
from recovered_resources import WORLD_GPU


def sha(x):return hashlib.sha256(x).hexdigest()

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--rom',type=Path,required=True)
 ap.add_argument('--reference',type=Path,required=True)
 ap.add_argument('--output',type=Path,default=ROOT/'build/source_world_gpu_verification.json')
 args=ap.parse_args()
 rom=load_rom(args.rom);reference=load_rom(args.reference)
 if len(rom)!=0x200000 or len(reference)!=0x200000:raise ValueError('Expected 2 MiB ROMs')
 meta=json.loads((ROOT/'assets/native/resources/packed/resources.json').read_text())['resources']
 world_packs=json.loads((ROOT/'build/source_world_gpu_index.json').read_text())
 maplog=(ROOT/'build/source_link_trial.log').read_text()
 rows=[]
 for rec in meta:
  if rec['rom_start'] not in WORLD_GPU:continue
  name,offset=WORLD_GPU[rec['rom_start']]
  symbol=next(x['symbol'] for x in world_packs if x['rom_start']==hex(rec['rom_start']))
  match=re.search(r'(?<![A-Za-z0-9_])'+re.escape(symbol)+r'\s+G\s+([0-9A-Fa-f]{8})\b',maplog)
  if not match:raise RuntimeError(f'{symbol}: missing from link map')
  loadaddr=int(match.group(1),16)
  romoff=loadaddr-0x800000
  if not 0<=romoff<len(rom):raise ValueError(f'{symbol}: invalid linked offset {romoff:#x}')
  dec=zlib.decompressobj(31);raw=dec.decompress(rom[romoff:]);raw+=dec.flush()
  if not dec.eof:raise ValueError(f'{symbol}: malformed gzip at linked offset {romoff:#x}')
  packed_len=len(rom)-romoff-len(dec.unused_data)
  compiled=(ROOT/'build/gpu'/f'{name}.bin').read_bytes()
  assert len(compiled)=={'gpustud':514,'gpugara':308,'gpuhouse':872,'gpucity':308}[name]
  if raw[offset:offset+len(compiled)]!=compiled:raise AssertionError(f'{symbol}: linked world does NOT use edited GPU source')
  generated=(ROOT/'build/packed_sources'/f'{rec["rom_start"]:06X}.gz').read_bytes()
  if generated!=rom[romoff:romoff+packed_len]:raise AssertionError(f'{symbol}: linked stream not generated from current source')
  oldworld=zlib.decompress(reference[rec['rom_start']:rec['rom_end']],31)
  diffs=[i for i,(a,b) in enumerate(zip(oldworld,raw)) if a!=b]
  if len(oldworld)!=len(raw):raise ValueError(f'{symbol}: changed decompressed world size')
  rows.append(dict(world=symbol,source_gpu=name,rom_offset=f'0x{romoff:06X}',
      original_rom_offset=f'0x{rec["rom_start"]:06X}',gpu_uncompressed_offset=offset,
      gpu_bytes=len(compiled),gpu_sha256=sha(compiled),linked_gzip_bytes=packed_len,
      decompressed_bytes=len(raw),changed_from_retail_bytes=len(diffs),
      changed_byte_positions=diffs[:24],world_sha256=sha(raw),verified=True))
  print(f'{symbol}: {name} {len(compiled)} compiled GPU bytes embedded at linked ROM offset {romoff:#08x}; world diffs {len(diffs)}')
 if len(rows)!=4:raise AssertionError('Expected four world-local compiled GPUs')
 report={'pass':True,'cartridge_sha256':sha(rom),'world_gpu_programs':rows}
 args.output.parent.mkdir(exist_ok=True,parents=True)
 args.output.write_text(json.dumps(report,indent=2)+'\n')
 print('PASS: 4/4 source-assembled world GPU programs verified *inside* linked ROM')
if __name__=='__main__':main()
