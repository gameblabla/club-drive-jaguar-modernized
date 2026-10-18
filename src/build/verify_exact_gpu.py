#!/usr/bin/env python3
"""Independent comparison of source assembled Tom/GPU binaries and retail bytes.

Reference is used ONLY as a byte-for-byte validation oracle, never to construct
these GPU binaries; builder --fallback '' is the only permitted mode.
"""
from pathlib import Path
import sys, json, argparse, hashlib,struct
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
from gpu_containerize import RETAIL_HEADERS, RETAIL_MATCH
from link_recovered_stage import load_rom

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--reference',type=Path,required=True)
 ap.add_argument('--before-container',action='store_true');ap.add_argument('--allow-edited-world-gpu',action='store_true');a=ap.parse_args()
 ref=load_rom(a.reference)
 result=[]
 for name,off in {**RETAIL_MATCH,**{n:p+8 for n,p in RETAIL_HEADERS.items()}}.items():
  orig=Path(ROOT/'build/gpu'/f'{name}.bin').read_bytes()
  if name in RETAIL_HEADERS:
   loc=RETAIL_HEADERS[name]
   origin,length=struct.unpack_from('>II',ref,loc)
   assert length and length<=4096,(name,length)
  else:length=len(orig)
  expected=ref[off:off+length]
  ok=orig==expected
  result.append({'name':name,'bytes':len(orig),'match':ok,'sha256':hashlib.sha256(orig).hexdigest()})
  print(f'{name:10} {len(orig):5} bytes: '+('EXACT' if ok else 'DIFFERENT'))
 # Four other original GPU kernels are stored inside gzip-compressed world
 # resources; compare assembled bytes at their verified decompressed offsets.
 resources=json.loads((ROOT/'assets/native/resources/packed/resources.json').read_text())['resources']
 for item in resources:
  if not item.get('known_gpu'):continue
  name=item['known_gpu']
  kernel=(ROOT/'build/gpu'/f'{name}.bin').read_bytes()
  raw=(ROOT/'assets/native/resources/packed'/item['file']).read_bytes()
  offset=item['gpu_uncompressed_offset']
  ok=raw[offset:offset+len(kernel)]==kernel
  result.append({'name':name,'bytes':len(kernel),'match':ok,'world_rom_offset':hex(item['rom_start']),'embedded_offset':offset,'sha256':hashlib.sha256(kernel).hexdigest()})
  print(f'{name:10} {len(kernel):5} bytes: '+('EXACT (world local)' if ok else 'EDITED (world local)' if a.allow_edited_world_gpu else 'DIFFERENT (world local)'))
 if len(result)!=21:raise SystemExit(f'Expected 21 source GPU binaries, got {len(result)}')
 (ROOT/'build/gpu_source_exact.json').write_text(json.dumps(result,indent=2)+'\n')
 if any(not x['match'] and (not a.allow_edited_world_gpu or 'world_rom_offset' not in x) for x in result):
  raise SystemExit('At least one ROM-resident GPU binary differs from retail without explicit world edit permission')
 print('All 17 main GPU programs match retail; 4 world kernels match or were explicitly edited from assembly source')
if __name__=='__main__':main()
