#!/usr/bin/env python3
"""Verify source-built data and GPU binary exact matches against retail ROM.

Usage: python3 build/compare_rom.py '/path/to/Club Drive (World).j64'
"""
from pathlib import Path
import hashlib, json, struct, sys
rom=Path(sys.argv[1]).read_bytes() if len(sys.argv)>1 else None
if rom is None: raise SystemExit('Need reference retail ROM path argument')
report={'rom_size':len(rom),'rom_sha256':hashlib.sha256(rom).hexdigest(),'exact_matches':[],'fragment_matches':[]}
# PLAYDATA position is independently determined from the unique font sequence.
font=bytes.fromhex('3e033e3e633e3e3e3e3e3e7c3e783e3e')
start=rom.find(font)
p=Path('build/obj/playdata.o').read_bytes(); t,d=struct.unpack('>II',p[4:12]); buf=p[32+t:32+t+d]
if start>=0 and rom[start:start+len(buf)]==buf:
 report['exact_matches'].append({'name':'playdata.s assembled data','offset':start,'size':len(buf)})
for name in ['art']:
 q=Path('build/obj/'+name+'.o')
 if q.exists():
  b=q.read_bytes();t,d=struct.unpack('>II',b[4:12]);section=b[32:32+t]
  import zlib
  hits=[];pos=0
  while (pos:=rom.find(b'\x1f\x8b\x08',pos))>=0:
   try:
    x=zlib.decompressobj(31);decoded=x.decompress(rom[pos:]);
    if x.eof and decoded==section: hits.append(pos)
   except zlib.error:pass
   pos+=1
  if hits: report['exact_matches'].append({'name':'ART.S inside retail gzip','offset':hits[0],'size':len(section)})
for file in sorted(Path('build/gpu').glob('*.bin')):
 b=file.read_bytes();where=rom.find(b)
 if where>=0:report['exact_matches'].append({'name':file.name,'offset':where,'size':len(b)})
for file in sorted(Path('build/obj').glob('*.o')):
 if file.name=='art.o':continue
 b=file.read_bytes()
 if b[:4]!=b'\x00\x00\x01\x07':continue
 t=struct.unpack('>I',b[4:8])[0]
 if t==0:continue
 section=b[32:32+t]
 hits=[]
 for i in range(0,max(0,len(section)-32),4):
  chunk=section[i:i+32]
  if chunk.count(0)>9:continue
  off=rom.find(chunk)
  if off>=0: hits.append([i,off])
 if hits:report['fragment_matches'].append({'module':file.name,'32_byte_window_matches':len(hits),'example_src_offset':hits[0][0],'example_rom_offset':hits[0][1]})
Path('build/compare_results.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
