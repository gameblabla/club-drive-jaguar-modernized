#!/usr/bin/env python3
"""Find 1994 game graphics and mask inputs through retail 68000 tables.

Unlike brute-force carving, graphic resource *starts* are read directly from
source-matched 'titlebkg', 'msk_sel' and 'loadscrs' runtime pointer tables.
Ends use the next start; the last loading image is bounded by the exact
source-matched dejagst decompressor address at $852E30 in SYS.S.
The original graphics-specific compressor is NOT rebuilt yet.
"""
from pathlib import Path
import json,hashlib,struct
from link_recovered_stage import load_rom
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/native/graphics/encoded'
FORMAT_TITLE=[('titlebk','titlebk.jag',56,0x4600),('rokltrs','rokltrs.jag',56,0x4600),
              ('seamap','seamap.jag',56,0x4600),('mp_club','mp_club.jag',20,0x3A00),
              ('mp_bill','mp_bill.jag',24,0x3C00),('credits','credits.jag',56,0x4600)]
FORMAT_MASK=[('mp_futm','mp_fut.m',0x004300E0,0x754),('mp_sfm','mp_sf.m',0x007100C0,0xA98),
             ('mp_wstm','mp_wst.m',0x005B00E0,0x9F4),('mp_hsm','mp_hs.m',0x00600100,0xC00),
             ('mp_hs2m','mp_hs2.m',0x002D00E0,0x4EC),('mp_clbm','mp_club.m',0x005000A0,0x640),
             ('mp_bilm','mp_bill.m',0x006000C0,0x900)]
# Pointer order is exactly play.s 'loadscrs' data table.
LOADING=['loadvp','loadsf','loadwst','loadhs','loadtod','loadgrc']
# The following byte sequence is the eight distinctive 16-bit constants
# at the beginning of play.s ldscrxy (and not an arbitrary ROM heuristic).
LOADXY=bytes.fromhex('005a00c000e0010c002401060140006c')


def locate(rom):
 titlemark=bytes.fromhex('0000003800004600')
 options=[];pos=0
 while (pos:=rom.find(titlemark,pos))>=0:
  base=pos-8
  if base<0:break
  try:
   rows=[struct.unpack_from('>IIII',rom,base+16*i) for i in range(6)]
   if all(0x800000<=r[0]<0x860000 and r[2:]==(width,flag)
          for r,(_,_,width,flag) in zip(rows,FORMAT_TITLE)):
    # Original table's source order has a club sign then billboard.
    options.append(base)
  except struct.error:pass
  pos+=1
 if len(options)!=1:raise ValueError('Cannot uniquely find source-described tables.s graphics pointer table: '+str(options))
 tb=options[0]
 result=[]
 for i,(label,fn,_,_) in enumerate(FORMAT_TITLE):
  addr=struct.unpack_from('>I',rom,tb+16*i)[0]
  result.append({'symbol':label,'original_filename':fn,'start':addr-0x800000,
                 'evidence':f'tables.s table at ROM {tb:#x}, slot {i}'})
 maskbase=tb+96
 for i,(label,fn,shape,size) in enumerate(FORMAT_MASK):
  row=struct.unpack_from('>IIIII',rom,maskbase+20*i)
  if row[2]!=shape or row[4]!=size:raise ValueError('tables.s mask parameters differ at row '+str(i))
  addr=row[3]
  if not (0x800000<=addr<0x860000):raise ValueError('Invalid mask data address')
  result.append({'symbol':label,'original_filename':fn,'start':addr-0x800000,
                 'decompressed_length_declared':size,
                 'evidence':f'tables.s mask table ROM {maskbase:#x}, row {i}'})
 if rom.count(LOADXY)!=1:raise ValueError('Cannot uniquely locate play.s ldscrxy signature')
 pos=rom.index(LOADXY)
 rowbase=pos-4*6
 for i,label in enumerate(LOADING):
  addr=struct.unpack_from('>I',rom,rowbase+4*i)[0]
  if not (0x800000<=addr<0x860000):raise ValueError('Invalid loading resource pointer')
  result.append({'symbol':label,'original_filename':label+'.jag','start':addr-0x800000,
                 'evidence':f'play.s loadscrs near ROM {rowbase:#x}, row {i}'})
 if len(result)!=19 or len({e['start'] for e in result})!=19:raise AssertionError('Duplicate resource offsets')
 return sorted(result,key=lambda x:x['start'])

def main(reference):
 rom=load_rom(reference)
 if hashlib.sha256(rom).hexdigest()!='dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289':
  raise ValueError('ROM does not match documented cartridge')
 resources=locate(rom)
 OUT.mkdir(parents=True,exist_ok=True)
 for i,row in enumerate(resources):
  if i+1<len(resources):end=resources[i+1]['start']
  else:end=0x561D0 # verified beginning of complete original sound bank
  if row['symbol']=='loadgrc':end=min(end,0x52E30) # sys.s ld_decmp lea dejagst ($852E30)
  row['slot_end']=end
  row['slot_length']=end-row['start']
  row['boundary_confidence']='source-matched next GPU decompressor address' if row['symbol']=='loadgrc' else ('adjacent verified pointer' if i+1<len(resources) else 'sound-bank start, pointer boundary inferred')
  if end<=row['start'] or end>len(rom):raise AssertionError('Invalid resource region')
  dat=rom[row['start']:end]
  if row['original_filename'].endswith('.jag') and dat[:4]!=b'\x00\x01\x00\x02' and dat[:4]!=b'\x00\x01\x00\x01':
   raise ValueError('Graphics compression header unexpected at '+hex(row['start']))
  row['sha256']=hashlib.sha256(dat).hexdigest()
  (OUT/row['original_filename']).write_bytes(dat)
 (OUT/'graphics_index.json').write_text(json.dumps({'reference_sha256':hashlib.sha256(rom).hexdigest(),
    'resources':resources,'notes':['Offsets verified by CPU data tables and 1994 Makefile source.',
    'Extraction is the entire fixed address span; the final loading graphic is bounded by sys.s decompressor entry.',
    'Original .jag compressed graphics format not yet converted to decompressed PNG.']},indent=2)+'\n')
 print('Recovered',len(resources),'pointer-anchored image/mask slots; total bytes',sum(r['slot_length'] for r in resources))
 for r in resources:print(r['symbol'],hex(r['start']),r['slot_length'],r['original_filename'])

if __name__=='__main__':
 import sys
 if len(sys.argv)!=2:raise SystemExit('Usage: recover_graphics_assets.py reference.j64|zip')
 main(Path(sys.argv[1]))
