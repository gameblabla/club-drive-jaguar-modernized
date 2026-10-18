#!/usr/bin/env python3
"""Make human-viewable previews from Jaguar CRY16 PNG byte-source files.

The original editable PNG files encode CRY high/low bytes in R/G channels
losslessly. Their B channel is only a placeholder. This module converts the
source CRY bytes to an RGB preview using the Virtual Jaguar color lookup tables.
Previews are informational and should NOT be edited for recompilation.
"""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
T=json.loads((ROOT/'build/cry_palette_tables.json').read_text())

def preview(src,dst):
 im=Image.open(src)
 if im.mode!='RGB':raise ValueError(f'{src}: expected RGB byte-source')
 raw=im.tobytes();rgb=bytearray()
 r,g,b=T['redcv'],T['greencv'],T['bluecv']
 for i in range(0,len(raw),3):
  hi,lo=raw[i],raw[i+1];c=hi>>4;t=hi&0xF
  rgb.extend((r[c][t]*lo>>8,g[c][t]*lo>>8,b[c][t]*lo>>8))
 out=Image.frombytes('RGB',im.size,bytes(rgb))
 out.save(dst,optimize=True)
 print(dst,im.size)

if __name__=='__main__':
 for key in ('yourit','youwin'):
  preview(ROOT/'assets/graphics/artwork'/f'{key}.png',ROOT/'assets/graphics/artwork'/f'{key}_preview.png')
 for key in ('1BF258_sky_cry16','1CA550_garage_sky_cry16'):
  preview(ROOT/'assets/native/resources/packed'/f'{key}.png',ROOT/'assets/native/resources/packed'/f'{key}_preview.png')
