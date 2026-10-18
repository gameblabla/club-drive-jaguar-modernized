#!/usr/bin/env python3
"""Lossless PNG sources for Club Drive's original CRY16 hood and game-over image.

The PNG R/G channels contain the exact original high/low CRY pixel bytes.
Preview PNGs are accurate rendered RGB using the original Jaguar CRY tables.
Only source PNGs (*_cry16.png without _preview) may be edited for recompilation.
"""
from pathlib import Path
from PIL import Image
import sys,json
ROOT=Path(__file__).resolve().parent.parent
DIR=ROOT/'assets/native/resources/packed'
ASSETS={0x1F4380:('hood_cry16',320,60),0x1F4BB0:('gameover_cry16',160,104)}

def preview_bytes(source):
 tables=json.loads((ROOT/'build/cry_palette_tables.json').read_text())
 red,green,blue=tables['redcv'],tables['greencv'],tables['bluecv']
 rgb=bytearray()
 for i in range(0,len(source),2):
  hi,lo=source[i:i+2];c=hi>>4;t=hi&15
  rgb.extend((red[c][t]*lo>>8,green[c][t]*lo>>8,blue[c][t]*lo>>8))
 return bytes(rgb)

def run(action):
 if action not in {'export','apply'}:raise ValueError('export or apply')
 res=json.loads((DIR/'resources.json').read_text())['resources']
 mapping={r['rom_start']:r for r in res}
 for offset,(name,w,h) in ASSETS.items():
  rec=mapping[offset]
  bfile=DIR/rec['file']
  assert bfile.name==f'{offset:06X}_{name}.bin'
  png=DIR/f'{offset:06X}_{name}.png'
  preview=DIR/f'{offset:06X}_{name}_preview.png'
  if action=='export':
   raw=bfile.read_bytes();assert len(raw)==w*h*2
   if not png.exists():
    pixels=bytes(c for i in range(0,len(raw),2) for c in (raw[i],raw[i+1],raw[i+1]))
    Image.frombytes('RGB',(w,h),pixels).save(png,optimize=True)
   if not preview.exists():Image.frombytes('RGB',(w,h),preview_bytes(raw)).save(preview,optimize=True)
   print('Exported',png,preview)
  else:
   im=Image.open(png)
   if im.size!=(w,h) or im.mode!='RGB':raise ValueError(f'{png} must be RGB {w}x{h}')
   encoded=im.tobytes()
   raw=bytes(c for i in range(0,len(encoded),3) for c in encoded[i:i+2])
   # Deterministic repeatable conversion; no palette or color-space loss.
   current=bfile.read_bytes()
   if len(raw)!=len(current):raise ValueError('CRY image changed dimensions')
   bfile.write_bytes(raw)
   print(name, 'source pixels:',w*h,'changed CRY bytes:',sum(x!=y for x,y in zip(raw,current)))

if __name__=='__main__':
 if len(sys.argv)!=2:raise SystemExit('Usage: compile_scene_graphics.py export|apply')
 run(sys.argv[1])
