#!/usr/bin/env python3
"""Club Drive Jaguar audio extraction and fixed-layout sound resource compilation.

Reconstructs all 42 named .f16 and 7 named .scr from *actual retail ROM
addresses*, corroborated by original sound.s and MAKEFILE. The .f16 files
are original DSP sample bytes (not decoded WAV). Music scores end with the
0x7fffffff word used in sound.s/playmus. Edits must preserve original sizes.
"""
from __future__ import annotations
from pathlib import Path
import argparse,hashlib,json,re,struct,sys

BASE=Path(__file__).resolve().parent.parent
OUT=BASE/'assets/native/audio/bank'
META=OUT/'audio_index.json'
SAMPLES=['winsnd','crashsnd','flushsnd','pianosnd','meowsnd','mousesnd','doorsnd','ouchsnd','p1yea','p2yea']
SAMPLE_LENGTHS=[18774//2,42510//2,56011,8370,22409,2142,24254,20941,26966//2,15344//2]
BANK_START=0x561d0
BANK_END=0xe5690
SONGS=['congams','honky','sfjazz','tech','rapmus','reggae','clubwave']
TEMPI=[0x56,0x2e,0x60,0x50,0x60,0x48,0x35]
TABLE=0x8014
SCORE_TABLE=0x7d44
PATCH_START=0x884c
PATCH_END=0x9b5c

def sha(b):return hashlib.sha256(b).hexdigest()
def u32(data,off):return struct.unpack_from('>I',data,off)[0]
def parse_names():
 text=(BASE/'makefile').read_text(errors='replace')
 return {sym.lower():name for name,sym in re.findall(r'-i\s+([^\s]+\.(?:f16|scr))\s+(\w+)',text,re.I)}

def collect(rom):
 if len(rom)!=2097152:raise ValueError('Expected the original 2MiB Jaguar cartridge')
 names=parse_names()
 if len(names)!=49:raise ValueError(f'Expected 49 unique sound symbols, found {len(names)}')
 entries={}
 # The ten fixed-effect pointers immediately precede the playback-rate/length tables.
 if [u32(rom,0x8084+4*i) for i in range(10)]!=SAMPLE_LENGTHS:
  raise ValueError('sound.s sample-length table does not match the retail executable')
 rates=[200,150,200,200,300,200,200,170,200,200]
 if [u32(rom,0x805c+4*i) for i in range(10)]!=rates:
  raise ValueError('sound.s playback-rate table does not match the retail executable')
 for i,symbol in enumerate(SAMPLES):
  address=u32(rom,TABLE+i*4);start=address-0x800000;length=SAMPLE_LENGTHS[i]
  if not 0x2000<=start<len(rom)-length:raise ValueError(f'Bad sound address for {symbol}')
  entries[symbol]={'file':names[symbol],'symbol':symbol,'rom_start':start,
                   'size':(13504 if symbol=='p1yea' else length),'played_sample_length':length,'address':hex(address),'kind':'f16',
                   'evidence':f'sound.s snd_addr[{i}], samplen[{i}] at ROM 0x8014/0x8084'}
 # Seven sequential four-long score records include JPIT2 timing words.
 if [u32(rom,SCORE_TABLE+16*i+12) for i in range(7)]!=TEMPI:
  raise ValueError('Music score pointer/timing table is not recognized')
 for i,symbol in enumerate(SONGS):
  address=u32(rom,SCORE_TABLE+i*16);start=address-0x800000
  if not 0x2000<=start<len(rom):raise ValueError(f'Bad song pointer {symbol}')
  # sound.s copies until the first 0x7fffffff longword. Search only aligned words.
  end=None
  for off in range(start,min(start+262144,len(rom)-3),4):
   if u32(rom,off)==0x7fffffff:end=off+4;break
  if end is None:raise ValueError(f'Missing score terminator {symbol}')
  entries[symbol]={'file':names[symbol],'symbol':symbol,'rom_start':start,
                   'size':end-start,'address':hex(address),'kind':'scr',
                   'evidence':f'sound.s mus_info[{i}] at ROM 0x7D44, terminated by 0x7FFFFFFF'}
 # Identify instrument samples through the original patch declarations: a 20-long
 # sampled-voice record starts with $20, has its address at +8 and sample
 # length at +16. Their original sequential order removes same-length ambiguity.
 lines=(BASE/'sound.s').read_text(errors='replace').splitlines()
 last=PATCH_START-4
 matches=[]
 for line_index,line in enumerate(lines):
  symmatch=re.match(r'^\s*(?:\.)?dc\.l\s+([a-zA-Z_]\w*)\s*(?:;.*)?$',line,re.I)
  if not symmatch:continue
  symbol=symmatch.group(1).lower()
  if symbol in SAMPLES or symbol in SONGS or symbol not in names:continue
  expression=lines[line_index+2].partition(';')[0].strip()
  lengthmatch=re.search(r'\(\((\d+(?:/2)?)\)\s*<<\s*8\s*\)\s*-\s*1',expression)
  if not lengthmatch:continue
  size=int(eval(lengthmatch.group(1),{'__builtins__':{}}))
  signature=(size<<8)-1
  matches_at=[]
  for pos in range(max(PATCH_START+16,last+4),PATCH_END,4):
   if (u32(rom,pos)==signature and u32(rom,pos-16)==0x20
       and 0x800000<=u32(rom,pos-8)<0xa00000):
    matches_at.append(pos)
  if not matches_at:raise ValueError(f'Unmatched instrument patch {symbol} source line {line_index+1} length={size}')
  pos=matches_at[0];last=pos;address=u32(rom,pos-8)
  matches.append({'symbol':symbol,'source_line':line_index+1,'rom_patch_length_offset':pos,
                  'sample_length':size,'address':hex(address)})
  if symbol in entries:
   item=entries[symbol]
   if item['address']!=hex(address):raise ValueError(f'{symbol} references two sample addresses')
   item['size']=max(item['size'],size)
   item.setdefault('patch_records',[]).append(pos-16)
  else:
   entries[symbol]={'file':names[symbol],'symbol':symbol,'rom_start':address-0x800000,
                   'size':size,'address':hex(address),'kind':'f16',
                   'patch_records':[pos-16],
                   'evidence':'sound.s instrument patch (type 0x20/address/sample length)'}
 if len(entries)!=len(names):
  raise ValueError('Missing audio symbols: '+str(sorted(set(names)-set(entries))))
 positions=sorted((x['rom_start'],x['rom_start']+x['size'],x['symbol']) for x in entries.values())
 for (_,end,sym),(nextstart,_,nextsym) in zip(positions,positions[1:]):
  if end>nextstart:raise ValueError(f'Audio assets overlap: {sym}, {nextsym}')
 for symbol,rec in entries.items():
  if not 0x2000<=rec['rom_start']<len(rom)-rec['size']:raise ValueError('Out-of-bounds '+symbol)
  rec['sha256']=sha(rom[rec['rom_start']:rec['rom_start']+rec['size']])
 return {'reference_sha256':sha(rom),'asset_count':len(entries),
         'sample_count':sum(x['kind']=='f16' for x in entries.values()),
         'bank_start':BANK_START,'bank_end':BANK_END,
         'score_count':sum(x['kind']=='scr' for x in entries.values()),
         'patch_references':matches,
         'assets':sorted(entries.values(),key=lambda r:r['rom_start'])}

def extract(rom,overwrite=False):
 metadata=collect(rom)
 OUT.mkdir(parents=True,exist_ok=True)
 for rec in metadata['assets']:
  path=OUT/rec['file'];data=rom[rec['rom_start']:rec['rom_start']+rec['size']]
  if path.exists() and not overwrite:
   if path.stat().st_size!=len(data):raise ValueError(f'{path} changed size; refusing to overwrite')
  else:path.write_bytes(data)
 META.write_text(json.dumps(metadata,indent=2)+'\n')
 assemble_bank(rom,metadata)
 print(f"Recovered {metadata['sample_count']} F16 sounds and {metadata['score_count']} music scores ({sum(x['size'] for x in metadata['assets'])} bytes)")
 return metadata

def assemble_bank(rom,metadata=None):
 """Prove the entire 586,944-byte audio region is reproducible from files and zero padding."""
 if metadata is None:metadata=json.loads(META.read_text())
 start=metadata['bank_start'];end=metadata['bank_end']
 if start!=BANK_START or end!=BANK_END:raise ValueError('Unexpected audio bank bounds')
 combined=bytearray(end-start)
 for rec in metadata['assets']:
  off=rec['rom_start']-start;size=rec['size'];b=(OUT/rec['file']).read_bytes()
  if len(b)!=size:raise ValueError(f'{rec["file"]}: expected {size} bytes; got {len(b)}')
  if rec['kind']=='scr' and b[-4:]!=bytes.fromhex('7fffffff'):
   raise ValueError(f'{rec["file"]}: invalid score terminator')
  combined[off:off+size]=b
 if rom is not None and combined!=rom[start:end]:
  diffs=[i for i,(a,b) in enumerate(zip(combined,rom[start:end])) if a!=b]
  if len(diffs) and any(rom[start+i]!=0 for i in diffs):
   raise ValueError(f'Sound bank reconstruction leaves nonzero unmapped retail data: {len(diffs)} bytes; first {diffs[0]:x}')
 (OUT/'SOUND_BANK.bin').write_bytes(combined)
 return bytes(combined)

def generate_asm(metadata):
 """Emit an RMAC relocatable object exporting all 49 actual original symbols."""
 import subprocess,struct
 ordered_symbols=[sym.lower() for name,sym in re.findall(
  r'-i\s+([^\s]+\.(?:f16|scr))\s+(\w+)', (BASE/'makefile').read_text(), re.I)]
 lookup={x['symbol']:x for x in metadata['assets']}
 lines=['; Generated from original MAKEFILE, sound.s and retail ROM.',
        '; Real recovered samples/scores; no placeholder audio.', ' .data']
 cursor=BANK_START
 for sym in ordered_symbols:
  item=lookup[sym];off=item['rom_start'];file=item['file']
  if off<cursor:raise ValueError('Overlapping sound objects')
  while cursor<off:
   lines.append(' dc.b $00');cursor+=1
  lines.append(f'{sym}::')
  lines.append(f' incbin "assets/native/audio/bank/{file}"')
  cursor+=item['size']
  if cursor%8:
   lines.append(' .phrase');cursor=(cursor+7)//8*8
 if cursor!=BANK_END:raise ValueError(f'Wrong bank end: {cursor:x} != {BANK_END:x}')
 file=BASE/'sounds_reconstructed.s';file.write_text('\n'.join(lines)+'\n')
 return file

def apply(rom,image):
 """Patch editable samples/scores into a ROM without touching other bytes."""
 if not META.exists():raise FileNotFoundError('Run recover_audio.py extract first')
 m=json.loads(META.read_text())
 if m['reference_sha256']!=sha(rom):raise ValueError('Audio manifest ROM SHA256 mismatch')
 original=collect(rom)
 if [(x['symbol'],x['rom_start'],x['size'],x['sha256']) for x in original['assets']] != [(x['symbol'],x['rom_start'],x['size'],x['sha256']) for x in m['assets']]:
  raise ValueError('Audio manifest no longer matches original source and ROM')
 edits=[]
 for rec in m['assets']:
  start=rec['rom_start']; size=rec['size'];path=OUT/rec['file']
  b=path.read_bytes()
  if len(b)!=size:raise ValueError(f'{path} length changed: {len(b)} != {size}, would relocate data')
  if rec['kind']=='scr' and b[-4:]!=b'\x7f\xff\xff\xff':
   raise ValueError(f'{path} lacks score terminator')
  if b!=rom[start:start+size]:
   image[start:start+size]=b
   edits.append({'file':rec['file'],'symbol':rec['symbol'],'rom_offset':hex(start),
                 'size':size,'changed_bytes':sum(a!=c for a,c in zip(b,rom[start:start+size]))})
 bank=assemble_bank(None,m)
 image[BANK_START:BANK_END]=bank
 return edits

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('command',choices=['extract','reextract','validate'])
 p.add_argument('--reference',type=Path,required=True)
 a=p.parse_args()
 from recovered_resources import reference_data
 rom=reference_data(a.reference)
 if a.command in ('extract','reextract'):extract(rom,a.command=='reextract')
 else:
  image=bytearray(rom)
  changes=apply(rom,image)
  print(f'Validated all {len(json.loads(META.read_text())["assets"])} audio assets; {len(changes)} edited')
  if changes:print(json.dumps(changes,indent=2))
if __name__=='__main__':main()
