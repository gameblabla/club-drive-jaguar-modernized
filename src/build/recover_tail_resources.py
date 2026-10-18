#!/usr/bin/env python3
"""Recover the final six missing symbols via source-matched 68000 references.

4 gzip assets (whose original raw versions are already under
RECOVERED_RESOURCES), one uncompressed prompt graphic, and one CRY rewind icon.
No offsets are supplied to the linker without a unique validated pointer.
"""
from pathlib import Path
import json,hashlib,zlib,struct,sys
from link_recovered_stage import load_rom
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/native/graphics/final'
SHA='dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289'

def main(src):
 rom=load_rom(Path(src));assert hashlib.sha256(rom).hexdigest()==SHA
 # Executable instructions that carry the actual pointer as big-endian 32-bit
 # immediates. These offsets are found by searching UNIQUE source-matched
 # opcode-context strings; the sites themselves are not reused as data.
 # Multiple move.l #resource,_inptr appear; source-matched full location
 # contexts distinguish the four program sites.
 sites={
 'ttlcar': (0x3348,bytes.fromhex('23fc'),bytes.fromhex('0001d60e23fc')),
 'o_ldtext':(0xa298,bytes.fromhex('23fc'),bytes.fromhex('0001d60e23fc')),
 'o_coltxt':(0xa3c8,bytes.fromhex('23fc'),bytes.fromhex('0001d60e23fc')),
 'gameovr':(0xb124,bytes.fromhex('23fc'),bytes.fromhex('0001d60e23fc')),
 'o_p2txt':(0xa2e2,bytes.fromhex('41f9'),bytes.fromhex('43f9000200004eb9')),
 'REWIND':(0xa0a2,bytes.fromhex('227c'),bytes.fromhex('4eb900810f0e')),
 }
 # Sites are cross-checked against the exact source opcode shape and
 # original cartridge SHA. Later source modifications do not change their
 # addresses because this is a reference-retail address map.
 result=[]
 for symbol,(at,op,tail) in sites.items():
  if rom[at:at+len(op)]!=op or rom[at+len(op)+4:at+len(op)+4+len(tail)]!=tail:
   raise ValueError(f'{symbol} source opcode signature mismatch at {at:#x}')
  addr=struct.unpack_from('>I',rom,at+len(op))[0]
  if not (0x800000<=addr<0xa00000):raise ValueError(f'{symbol} pointer not cartridge-resident')
  result.append({'symbol':symbol,'start':addr-0x800000,'code_reference_offset':at,
                 'evidence':'title.s/play.s source-matched 68000 immediate pointer'})
 result.sort(key=lambda r:r['start'])
 known={'ttlcar':0x32318,'o_ldtext':0x1f1bd8,'o_coltxt':0x1f2260,
        'o_p2txt':0x1f2b80,'gameovr':0x1f4bb0,'REWIND':0x1f7af0}
 if any(r['start']!=known[r['symbol']] for r in result):raise ValueError('Unexpected position of original text/game resource')
 meta=json.loads((ROOT/'assets/native/resources/packed/resources.json').read_text())
 gzip_by_offset={e['rom_start']:e for e in meta['resources']}
 asset_info={'ttlcar':('ttlcar.z','gzip'), 'o_ldtext':('ldtext.z','gzip'),
             'o_coltxt':('coltext.z','gzip'),'gameovr':('gameovr.z','gzip'),
             'o_p2txt':('p2txt','raw'),'REWIND':('rewind.cry','raw')}
 OUT.mkdir(parents=True,exist_ok=True)
 for r in result:
  sym=r['symbol'];start=r['start'];fn,format=asset_info[sym]
  if format=='gzip':
   member=gzip_by_offset.get(start)
   if member is None:raise ValueError('Expected valid gzip resource at '+hex(start))
   end=member['rom_end'];data=rom[start:end]
   if zlib.decompress(data,31)!=(ROOT/'assets/native/resources/packed'/member['file']).read_bytes():
    raise ValueError('Original zipped resource does not match stored decoded data')
   r['uncompressed_bytes']=len(zlib.decompress(data,31));r['source_raw_file']=str(Path('assets/native/resources/packed')/member['file'])
  else:
   end=start+({'REWIND':64*16*2,'o_p2txt':192*16*2}[sym])
   data=rom[start:end]
   if sym=='o_p2txt' and end!=0x1f4380:raise ValueError('Prompt image not exactly adjacent to hood')
  r.update(original_filename=fn,format=format,slot_end=end,length=len(data),sha256=hashlib.sha256(data).hexdigest())
  (OUT/fn).write_bytes(data)
 (OUT/'final_assets_index.json').write_text(json.dumps({'reference_sha256':SHA,
 'resources':result,'note':'Proven original runtime cartridge addresses; native packed/raw assets preserved. Source JPEG/JAG converters are still unavailable.'},indent=2)+'\n')
 for r in result:print(r['symbol'],hex(r['start']),r['length'],r['format'])
if __name__=='__main__':
 if len(sys.argv)!=2:raise SystemExit('Usage: recover_tail_resources.py retail.zip|j64')
 main(sys.argv[1])
