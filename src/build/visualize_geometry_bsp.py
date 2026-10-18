#!/usr/bin/env python3
"""Orthographic PNG views of original ASC triangles and first generated split.

2026 inspection aid only; split is a prototype geometric halfspace, not a
runtime Jaguar BSP divider. This script never changes source data or the ROM.
"""
from pathlib import Path
import json, sys
from PIL import Image, ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parent))
import geometry_bsp as g
import asc_authoring as a

ROOT=Path(__file__).resolve().parent.parent
SOURCES=[Path('CARS/CAR2.ASC'),Path('ARENAS/RACE.ASC'),Path('HOUSE/STUDY.ASC')]


def preview(rel):
    asc_doc=json.loads(a.path_doc(rel).read_text())
    raw,_,_=a.gen_asc(rel,asc_doc)
    meshes=g.read_meshes(raw.decode('latin1'))
    bsp=json.loads(g.path(rel).read_text())
    if not meshes:return
    mesh=max(meshes,key=lambda m:len(m['faces']))
    layout=bsp['meshes'][[m['name'] for m in bsp['meshes']].index(mesh['name'])]
    verts=mesh['vertices'];root=layout['nodes'][0] if layout['nodes'] else None
    W=1200;H=590;im=Image.new('RGB',(W,H),(248,250,252));d=ImageDraw.Draw(im)
    d.text((22,15),f'{rel}  —  {mesh["name"]}: geometry BSP authoring preview',fill=(30,41,56))
    d.text((22,35),'Blue: original triangles   |   Red: root split plane if visible in this projection',fill=(70,86,100))
    for c,(i,j,label) in enumerate(((0,1,'X/Y'),(0,2,'X/Z'),(1,2,'Y/Z'))):
        lx=c*400+16;ly=75;w=366;h=455
        coords=[(v[i],v[j]) for v in verts]
        xmin=min(x for x,y in coords);xmax=max(x for x,y in coords)
        ymin=min(y for x,y in coords);ymax=max(y for x,y in coords)
        sc=min((w-24)/max(xmax-xmin,1), (h-24)/max(ymax-ymin,1))
        def tr(p):return (round(lx+w/2+(p[0]-(xmin+xmax)/2)*sc),round(ly+h/2-(p[1]-(ymin+ymax)/2)*sc))
        d.rectangle((lx,ly,lx+w,ly+h),outline=(202,211,221),width=2)
        for face in mesh['faces']:
            poly=[tr(coords[q]) for q in face['indices']]
            d.line(poly+[poly[0]],fill=(106,137,169),width=1)
        if root and root['type']=='split':
            ax='XYZ'.index(root['axis']);p=root['plane']
            if ax in (i,j):
                if ax==i: x=tr((p,(ymin+ymax)/2))[0];d.line((x,ly,x,ly+h),fill=(196,58,54),width=3)
                else: y=tr(((xmin+xmax)/2,p))[1];d.line((lx,y,lx+w,y),fill=(196,58,54),width=3)
        d.text((lx+12,ly+h+10),f'{label} view',fill=(42,52,64))
    out=g.BASE/'previews'/rel.with_suffix('.partition.png');out.parent.mkdir(parents=True,exist_ok=True);im.save(out)
    print('PNG',out.relative_to(ROOT),f'{len(mesh["faces"])} faces')

if __name__=='__main__':
    for f in SOURCES:preview(f)
