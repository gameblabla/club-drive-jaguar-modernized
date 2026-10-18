#!/usr/bin/env python3
"""Relocate the retail JPEG/dehuff binary tree's internal absolute pointers.

Atari's -i tool inserted a pre-linked binary blob built at $81D000.
Relinking it at a new address without fixing 172 embedded pointers leaves the
GPU reading unrelated cartridge words; the result is an unpainted title image.
No heuristic offset scanning: pointers are exactly big-endian 32-bit and
word-aligned, within the original 1392-byte dehuff structure.
"""
from pathlib import Path
import json, struct, hashlib, argparse
ROOT=Path(__file__).resolve().parent.parent
BASE=0x81D000
SIZE=1392

def relocate(origin):
 manifest=json.loads((ROOT/'assets/native/tools/helpers_index.json').read_text())
 source=ROOT/'assets/native/tools/dehuff.bin'
 rec=next(r for r in manifest['resources'] if r['symbol']=='dehuff')
 original=source.read_bytes()
 if len(original)!=SIZE or hashlib.sha256(original).hexdigest()!=rec['sha256']:
  raise ValueError('Original dehuff table does not match verified retail extract')
 out=bytearray(original); positions=[]
 for off in range(0,len(out)-3,4):
  val=struct.unpack_from('>I',out,off)[0]
  if BASE<=val<BASE+SIZE:
   positions.append((off,val))
   struct.pack_into('>I',out,off,val-BASE+origin)
 if len(positions)!=172:raise ValueError(f'Expected 172 dehuff internal absolute references; got {len(positions)}')
 file=ROOT/'build/relocated_resources/dehuff.bin';file.parent.mkdir(parents=True,exist_ok=True);file.write_bytes(out)
 result={'original_base':hex(BASE),'linked_base':hex(origin),'binary_length':SIZE,
  'absolute_references_relocated':len(positions),
  'first_relocations':[(hex(o),hex(v),hex(v-BASE+origin)) for o,v in positions[:8]],
  'binary_sha256':hashlib.sha256(out).hexdigest()}
 (file.parent/'dehuff_relocations.json').write_text(json.dumps(result,indent=2)+'\n')
 return result
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('new_origin',type=lambda s:int(s,0));a=p.parse_args()
 print(relocate(a.new_origin))
