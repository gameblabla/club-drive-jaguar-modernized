#!/usr/bin/env python3
"""2026 visual-only PNG previews (never compile these into game data).

Index8 sprites use grayscale surrogate colors (palette unknown). CRY16 sprites
are approximated using the Jaguar tables captured from the supplied emulator.
The editable source PNGs, not these previews, contain the exact game bytes.
"""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent.parent
GRAPH=ROOT/'assets/graphics/artwork'
TABLES=json.loads((ROOT/'build/cry_palette_tables.json').read_text())

def render_cry(im):
    red,green,blue=(TABLES[x] for x in ('redcv','greencv','bluecv'))
    pixels=im.tobytes();rgb=bytearray()
    for i in range(0,len(pixels),3):
        hi,lo=pixels[i],pixels[i+1];c,t=hi>>4,hi&15
        rgb.extend([red[c][t]*lo>>8, green[c][t]*lo>>8, blue[c][t]*lo>>8])
    return Image.frombytes('RGB',im.size,bytes(rgb))

def sprites():
    entries=json.loads((GRAPH/'art_png_index.json').read_text())['sprites']
    dest=GRAPH/'art_previews_png';dest.mkdir(exist_ok=True)
    rows=[]
    for item in entries:
        with Image.open(ROOT/item['png']) as src:
            if item['encoding']=='cry16':im=render_cry(src)
            else:im=src.convert('L').convert('RGB')
            im.save(dest/(item['name']+'.png'))
            rows.append((item['name'],im.copy()))
    return rows

def atlas(rows, out, cols=7, cell=(196,152), label=''):
    w,h=cell;rows_count=(len(rows)+cols-1)//cols
    canvas=Image.new('RGB',(w*cols,h*rows_count),(28,30,35))
    dr=ImageDraw.Draw(canvas)
    for i,(name,img) in enumerate(rows):
        x=(i%cols)*w;y=(i//cols)*h
        img.thumbnail((w-16,h-36),Image.Resampling.NEAREST)
        if max(img.size)<80: img=img.resize((min((w-16),img.width*3),min(h-36,img.height*3)),Image.Resampling.NEAREST)
        canvas.paste(img,(x+max(0,(w-img.width)//2),y+7))
        dr.text((x+8,y+h-22),name,fill=(230,230,230))
    canvas.save(out,optimize=True)

if __name__=='__main__':
    rows=sprites();atlas(rows,GRAPH/'ART_sprite_atlas.png')
    images=[]
    for p in sorted((ROOT/'assets/graphics/ui').glob('*.png')):
        with Image.open(p) as img:images.append((p.stem,img.convert('RGB').copy()))
    atlas(images,GRAPH/'original_artist_PNG_atlas.png')
    print(f'Created {len(rows)} ART preview PNGs and 2 image atlases')
