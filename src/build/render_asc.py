#!/usr/bin/env python3
"""Visual PNG diagnostic previews for ASC source meshes (2026 reconstruction).

These are model inspection images, NOT textures or runtime Jaguar assets.
Original X,Y,Z values are plotted in their native 3D Studio coordinates.
"""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont
import asc_authoring as asc
BASE=asc.BASE

def draw_one(rel,verts):
    im=Image.new('RGB',(480,280),(247,248,250));d=ImageDraw.Draw(im)
    d.text((16,12),str(rel),fill=(25,31,40))
    items={}
    for v in verts:items.setdefault(v['mesh'] or '(unnamed)',[]).append(v['xyz'])
    d.text((16,30),f'{len(verts)} vertices / {len(items)} mesh groups',fill=(75,85,99))
    for slot,(u,v,label) in enumerate(((0,1,'TOP (X/Y)'),(0,2,'SIDE (X/Z)'))):
        x0=12+slot*235;y0=55
        data=[p for g in items.values() for p in g]
        if not data:continue
        midx=(min(p[u] for p in data)+max(p[u] for p in data))/2
        midy=(min(p[v] for p in data)+max(p[v] for p in data))/2
        extent=max(max(p[u] for p in data)-min(p[u] for p in data),max(p[v] for p in data)-min(p[v] for p in data),1)
        mul=185/extent
        d.rectangle((x0,y0,x0+220,y0+195),outline=(210,216,225))
        for n,(mesh,points) in enumerate(items.items()):
            # Distinguish nested mesh groups without changing the original source.
            palette=[(24,73,120),(152,72,39),(44,125,95),(138,83,140),(104,109,36)]
            c=palette[n%len(palette)]
            for p in points:
                x=int(x0+110+(p[u]-midx)*mul);y=int(y0+100-(p[v]-midy)*mul)
                d.ellipse((x-1,y-1,x+1,y+1),fill=c)
        d.text((x0+4,254),label,fill=(75,85,99))
    out=BASE/'previews'/rel.with_suffix('.png');out.parent.mkdir(parents=True,exist_ok=True);im.save(out)
    return im

def main():
    files=asc.canonical_asc();allpics=[]
    for rel in files:
        doc=json.loads(asc.path_doc(rel).read_text())
        im=draw_one(rel,doc['vertices']);allpics.append((str(rel),im))
    cols=6;cw,ch=240,140;rows=math.ceil(len(allpics)/cols)
    sheet=Image.new('RGB',(cols*cw,rows*ch),(236,239,243))
    for idx,(rel,img) in enumerate(allpics):
        sheet.paste(img.resize((cw,ch),Image.Resampling.LANCZOS),((idx%cols)*cw,(idx//cols)*ch))
    sheet.save(BASE/'asc_model_catalog.png')
    print(f'ASC PNG PREVIEWS: {len(allpics)} and model catalog')
if __name__=='__main__':main()
