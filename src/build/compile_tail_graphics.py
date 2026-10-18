#!/usr/bin/env python3
"""Rebuild recovered uncompressed 16-bit Jaguar CRY graphics from editable PNG.

The source image encodes the exact high and low CRY bytes in PNG R,G
channels; a separate rendered RGB preview can be generated without changing
this lossless representation. Files must retain their exact original extent.
"""
from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/native/graphics/final'
IMAGES={'o_p2txt':(192,16),'REWIND':(64,16)}

def rows():
 manifest=json.loads((OUT/'final_assets_index.json').read_text())
 return [r for r in manifest['resources'] if r['symbol'] in IMAGES]

def export():
 for rec in rows():
  width,height=IMAGES[rec['symbol']]
  src=OUT/rec['original_filename']
  b=src.read_bytes()
  if len(b)!=width*height*2:raise ValueError('Jaguar CRY source incorrect size: '+rec['symbol'])
  png=OUT/(rec['symbol'].lower()+'_cry16.png')
  if png.exists():continue # never overwrite user's edited PNG
  img=Image.frombytes('RGB',(width,height),bytes(c for i in range(0,len(b),2) for c in (b[i],b[i+1],b[i+1])))
  img.save(png,optimize=True)
  print('Exported editable',png.relative_to(ROOT))

def apply(original,image):
 changes=[]
 for rec in rows():
  width,height=IMAGES[rec['symbol']]
  png=OUT/(rec['symbol'].lower()+'_cry16.png')
  img=Image.open(png)
  if img.mode!='RGB' or img.size!=(width,height):raise ValueError(f'{png}: expected {width}x{height} RGB')
  s=img.tobytes()
  b=bytes(c for i in range(0,len(s),3) for c in s[i:i+2])
  a,z=rec['start'],rec['slot_end']
  assert len(b)==z-a
  if b!=original[a:z]:
   (OUT/rec['original_filename']).write_bytes(b)
   image[a:z]=b
   changes.append({'symbol':rec['symbol'],'rom_start':a,'bytes':len(b),
                   'changed':sum(x!=y for x,y in zip(b,original[a:z]))})
  elif (OUT/rec['original_filename']).read_bytes()!=b:
   raise ValueError('Raw source and PNG are out of sync; restore one original first')
 return changes

if __name__=='__main__':
 import sys
 if len(sys.argv)!=2 or sys.argv[1]!='export':raise SystemExit('Usage: compile_tail_graphics.py export')
 export()
