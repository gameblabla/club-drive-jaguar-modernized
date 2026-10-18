#!/usr/bin/env python3
"""Locate never-yet-integrated GPU kernels conservatively in retail code/data.

No guessed overlay locations are permitted; this is only an audit.
"""
from pathlib import Path
from collections import Counter
import json,hashlib,zlib,zipfile
from recovered_resources import inflate_member
ROOT=Path(__file__).resolve().parent.parent


def run(rom):
 from link_recovered_stage import load_rom
 image=load_rom(rom)
 meta=json.loads((ROOT/'assets/native/resources/packed/resources.json').read_text())
 haystacks=[('ROM',image,0)]
 for rec in meta['resources']:
  raw=(ROOT/'assets/native/resources/packed'/rec['file']).read_bytes()
  haystacks.append((rec['label'],raw,rec['rom_start']))
 names='lighten cross fade gpunzip casbeg racbeg tagbeg casend racend tagend'.split()
 report=[]
 for name in names:
  needle=(ROOT/'build/gpu'/f'{name}.bin').read_bytes()
  exact=[];candidate=Counter();stride=2
  for label,hay,start in haystacks:
   pos=hay.find(needle)
   if pos>=0:exact.append({'space':label,'offset':hex(pos),'rom_resource_start':hex(start)})
   # Start at GPU binary word offsets, seek short distinct anchors.
   # An anchor is NOT a safe patch target; it only identifies a candidate.
   for n in range(0,len(needle)-15,16):
    chunk=needle[n:n+16]
    if chunk in (bytes(16),bytes.fromhex('ffffffffffffffffffffffffffffffff')):continue
    found=hay.find(chunk)
    hits=0
    while found>=0 and hits<100:
     base=found-n
     if base>=0 and base+len(needle)<=len(hay):candidate[(label,base,start)]+=1
     hits+=1;found=hay.find(chunk,found+1)
  ranked=[]
  for (label,base,start),anchors in candidate.most_common(4):
   hay=next(h for l,h,a in haystacks if l==label and a==start)
   at=hay[base:base+len(needle)]
   matching=sum(a==b for a,b in zip(at,needle))
   ranked.append({'space':label,'offset':hex(base),'resource_start':hex(start),'matching_bytes':matching,
      'total_bytes':len(needle),'matching_16byte_anchors':anchors})
  report.append({'name':name,'source_sha256':hashlib.sha256(needle).hexdigest(),
                 'size':len(needle),'exact':exact,'candidates':ranked})
  summary=ranked[0] if ranked else {}
  print(name,'exact',len(exact),'best',summary.get('space'),summary.get('offset'),summary.get('matching_bytes'),'/',len(needle))
 (ROOT/'build/gpu_remaining_match_report.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':
 import sys
 if len(sys.argv)!=2:raise SystemExit('Usage: match_remaining_gpu.py reference.zip')
 run(Path(sys.argv[1]))
