#!/usr/bin/env python3
"""Proof-oriented ROM same-offset audit for the cpu_layout Club Drive reconstruction.

Unlike a relocatable-window search, byte identity in this tool always means
identical *cartridge addresses*. It does not claim that the whole ROM is
source-created or equivalent for all possible gameplay states.
"""
from pathlib import Path
import argparse, hashlib, json, sys
from link_recovered_stage import load_rom

EXACT = ((0xB8E0, 0xFB7C), (0xFB80,0x10F9A),
         (0x11E00,0x12099), (0x12088,0x129E0))
RANGES = ((0x2000,0xBA00), (0x2000,0x1BA00),
          (0x2000,0x1D000), (0x12088,0x129E0), (0x128DC,0x129E0))

def count(a,b,x,y):return sum(p==q for p,q in zip(a[x:y],b[x:y]))
def sha(a):return hashlib.sha256(a).hexdigest()

def main():
 p=argparse.ArgumentParser()
 p.add_argument('--reference',required=True,type=Path)
 p.add_argument('--source',required=True,type=Path)
 p.add_argument('--previous',type=Path)
 p.add_argument('--out',type=Path,default=Path('build/cpu_audit.json'))
 a=p.parse_args()
 ref,src=load_rom(a.reference),load_rom(a.source)
 previous=load_rom(a.previous) if a.previous else None
 if len(ref)!=len(src) or len(src)!=0x200000:raise ValueError('Requires 2 MiB cartridges')
 if previous is not None and len(previous)!=len(ref):raise ValueError('Bad baseline ROM size')
 if src[0x400:0x408]!=bytes.fromhex('0404040400802000'):
  raise ValueError('Jaguar cartridge marker or entry address missing')
 checks=[]
 for x,y in RANGES:
  same=count(ref,src,x,y)
  baseline=count(ref,previous,x,y) if previous is not None else None
  row={'range':f'0x{x:06X}-0x{y:06X}', 'bytes':y-x,
       'source_identical_bytes':same,'previous_identical_bytes':baseline}
  if (x,y) in EXACT and same!=y-x:
   raise RuntimeError('Required retail-aligned region differs: '+row['range'])
  checks.append(row)
  print(row)
 for x,y in EXACT:
  if count(ref,src,x,y)!=y-x:raise RuntimeError(f'Lost exact byte landmark {x:x}-{y:x}')
 if previous is not None and count(ref,src,0x2000,0x1BA00)<=count(ref,previous,0x2000,0x1BA00):
  raise RuntimeError('Compared with original cpu_addresses: CPU parity did not improve')
 result={'reference_sha256':sha(ref),'source_sha256':sha(src),
         'cpu_addresses_sha256':sha(previous) if previous is not None else None,
         'rom_byte_differences':len(ref)-count(ref,src,0,len(ref)),
         'header_byte_differences':0x2000-count(ref,src,0,0x2000),
         'regions':checks, 'exact_regions':[f'0x{x:06X}-0x{y:06X}' for x,y in EXACT],
         'caveat':'Same-address bytes do not establish standalone asset-generator reconstruction, exact total-ROM identity, or untested gameplay parity.'}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(result,indent=2)+'\n')
 print('PASS strict retail CPU exact regions')

if __name__=='__main__':main()
