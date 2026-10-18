#!/usr/bin/env python3
"""Lossless, editable PNG source for the 4 missing Club Drive graphic includes.

Format is intentionally explicitly reversible rather than a guessed CRY palette:
  dashpal.png: P-mode 320x30, palette entries are byte indices unchanged
  yourit.png/youwin.png: RGB 64x32, R=CRY high byte, G=CRY low byte,
                       B=approximate preview luminance (ignored at compile)
  score.png: RGB 68x1, exactly 204 source bytes in RGB channel order.
PNG files are canonical authoring inputs; ROM_LIFTED/*.bin are compiled outputs.
"""
from pathlib import Path
from PIL import Image
import argparse
BASE=Path(__file__).resolve().parent.parent
A=BASE/'assets/graphics/artwork'; D=BASE/'assets/native/rom/fragments'
FORMATS={'dashpal':(320,30,'indexed'), 'yourit':(64,32,'cry16'), 'youwin':(64,32,'cry16'), 'score':(68,1,'rgb')}

def decode(n,data):
 w,h,fmt=FORMATS[n]
 if fmt=='indexed':
  assert len(data)==w*h
  im=Image.frombytes('P',(w,h),data)
  im.putpalette([v for i in range(256) for v in (i,i,i)])
 elif fmt=='cry16':
  assert len(data)==w*h*2
  buf=bytearray()
  for i in range(0,len(data),2):
   hi,lo=data[i:i+2]
   buf.extend((hi,lo,lo))
  im=Image.frombytes('RGB',(w,h),bytes(buf))
 else:
  assert len(data)==w*h*3
  im=Image.frombytes('RGB',(w,h),data)
 return im

def encode(n,path):
 w,h,fmt=FORMATS[n]
 im=Image.open(path)
 if im.size!=(w,h):raise ValueError(f'{n} image must be {w}x{h}, got {im.size}')
 if fmt=='indexed':
  if im.mode!='P':raise ValueError(f'{n} must be indexed PNG (P), not {im.mode}')
  return im.tobytes()
 if im.mode!='RGB':raise ValueError(f'{n} must be RGB PNG, not {im.mode}')
 data=im.tobytes()
 if fmt=='cry16':return bytes(v for i in range(0,len(data),3) for v in data[i:i+2])
 return data

def extract():
 A.mkdir(exist_ok=True)
 for n in FORMATS:
  data=(D/(n+'.bin')).read_bytes()
  path=A/(n+'.png')
  decode(n,data).save(path,format='PNG',optimize=True)
  assert encode(n,path)==data
  print('lossless export',path,len(data),'raw bytes')

def compile_png():
 D.mkdir(exist_ok=True)
 for n in FORMATS:
  data=encode(n,A/(n+'.png'))
  (D/(n+'.bin')).write_bytes(data)
  print('compiled',n+'.png','to',n+'.bin',len(data),'bytes')

if __name__=='__main__':
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('operation',choices=['export','compile'])
 args=ap.parse_args()
 (extract if args.operation=='export' else compile_png)()
