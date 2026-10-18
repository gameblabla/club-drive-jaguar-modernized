#!/usr/bin/env python3
"""2026 reconstruction: PNG authoring for Atari Jaguar ART.S display sprites.

Original 1994 comments are kept verbatim in ART_ORIGINAL_1994.S. ART.S is a
faithful annotated front-end with the original labels and PNG-compiled INCBIN
payloads. Indexed sprites use PNG palette indices as raw byte values; 16-bit
sprites use PNG R/G as the original high/low Jaguar CRY bytes. Their optional
*_preview.png files are DISPLAY ONLY. Packed 1bpp menu bar is expanded into
8-bit indexed PNG, then re-packed big-endian for the renderer.

This tool does not claim every packed binary in Club Drive is an image.
"""
from __future__ import annotations
import argparse, hashlib, json, re, struct
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parent.parent
ORIGINAL=ROOT/'ART_ORIGINAL_1994.S'
TARGET=ROOT/'ART.S'
IMAGES=ROOT/'assets/graphics/artwork/art_png'
BINARIES=ROOT/'build/png_art'
META=ROOT/'assets/graphics/artwork/art_png_index.json'
LABEL=re.compile(r'(?m)^([a-zA-Z_]\w*)::?\s*(?:;[^\n]*)?$')
DC=re.compile(r'(?m)^[ 	]*dc\.(b|w|l)\s+([^\n;]+)', re.I)


def asset_stem(name):
    # Two different glyphs, A and a, cannot have case-only filenames.
    if re.fullmatch(r'let_[A-Za-z]',name):
        glyph=name[-1]
        return 'let_' + ('upper_' if glyph.isupper() else 'lower_') + glyph
    return name

def sha(b):return hashlib.sha256(b).hexdigest()


def sections():
    text=ORIGINAL.read_text(encoding='latin1')
    labels=list(LABEL.finditer(text))
    for i,m in enumerate(labels):
        nextpos=labels[i+1].start() if i+1<len(labels) else len(text)
        yield m.group(1),text[m.start():m.end()],text[m.end():nextpos]


def original_bytes(sec):
    # car4 has a disabled historical alternate sprite: use the live .else arm.
    if '.if 0' in sec:
        sec=sec.split('.else',1)[1].split('.endif',1)[0]
    values=bytearray()
    for m in DC.finditer(sec):
        n={'b':1,'w':2,'l':4}[m.group(1).lower()]
        for v in m.group(2).split(','):
            v=v.strip()
            if not v:continue
            if v.startswith('$'):x=int(v[1:],16)
            else:x=int(v,0)
            values.extend((x&((1<<(n*8))-1)).to_bytes(n,'big'))
    return bytes(values)


def shape(name,sec,data):
    if name=='copyrt':return (192,7,'cry16')
    if name.startswith('car') and name.endswith('icn'):return (24,6,'index8')
    if name.startswith('curs'):return (8,13,'index8')
    if name=='volcrdta':return (8,7,'index8')
    if name=='bardata':return (192,11,'bit1')
    if name=='rankbox':return (96,24,'cry16')
    if name.startswith(('f16_','num16_')):return (8,7,'cry16')
    if name.startswith(('fnt_','num')):return (8,7,'index8')
    if name.startswith('let_'):
        dcs=list(DC.finditer(sec))
        # A 3D title-font glyph can be 8 or 16 pixels wide; original source
        # has one row per dc.b directive, so dimensions are recovered exactly.
        width=len([v for v in dcs[0].group(2).split(',') if v.strip()])
        return (width,len(dcs),'index8')
    raise ValueError(f'Unclassified sprite {name}')


def to_png(name,info,data):
    w,h,kind=info
    if kind=='index8':
        assert len(data)==w*h,(name,len(data),info)
        im=Image.frombytes('P',(w,h),data)
        im.putpalette([v for i in range(256) for v in (i,i,i)])
    elif kind=='cry16':
        assert len(data)==w*h*2,(name,len(data),info)
        pixels=bytes(c for j in range(0,len(data),2) for c in (data[j],data[j+1],data[j+1]))
        im=Image.frombytes('RGB',(w,h),pixels)
    else:
        assert kind=='bit1' and len(data)==(w*h+7)//8
        bits=bytes((data[i//8]>>(7-i%8))&1 for i in range(w*h))
        im=Image.frombytes('P',(w,h),bits)
        im.putpalette([v for i in range(256) for v in (i,i,i)])
    return im


def from_png(path,info):
    w,h,kind=info
    with Image.open(path) as im:
        if im.size!=(w,h):raise ValueError(f'{path}: expected {w}x{h}, got {im.size}')
        if kind in ('index8','bit1'):
            if im.mode!='P':raise ValueError(f'{path}: needs indexed P-mode PNG to preserve pixel indices')
            b=im.tobytes()
            if kind=='index8':return b
            if any(x not in (0,1) for x in b):raise ValueError(f'{path}: 1-bit image values must be 0 or 1')
            out=bytearray((len(b)+7)//8)
            for i,c in enumerate(b):out[i//8]|=c<<(7-i%8)
            return bytes(out)
        if im.mode!='RGB':raise ValueError(f'{path}: needs RGB with R/G = raw CRY16 bytes')
        p=im.tobytes()
        return bytes(v for i in range(0,len(p),3) for v in p[i:i+2])


def entries():
    return [(name,header,sec,shape(name,sec,original_bytes(sec)),original_bytes(sec)) for name,header,sec in sections()]


def export():
    IMAGES.mkdir(parents=True,exist_ok=True)
    manifest=[]
    new=[]
    for name,header,sec,info,raw in entries():
        filename=f'{asset_stem(name)}.png'
        path=IMAGES/filename
        # Creating from original source is explicit. Never silently overwrite
        # an existing edit when the export is rerun.
        if not path.exists():to_png(name,info,raw).save(path,format='PNG',optimize=True)
        decoded=from_png(path,info)
        if decoded!=raw:raise ValueError(f'{path}: pre-existing PNG differs from original: export refuses overwrite')
        manifest.append(dict(name=name,png=f'assets/graphics/artwork/art_png/{filename}',
                             dimensions=list(info[:2]),encoding=info[2],bytes=len(raw),sha256=sha(raw)))
        # Preserve the original label and any introductory Atari comments.
        # Replace only the pixel directives with an INCBIN generated from PNG.
        first=DC.search(sec)
        if not first:raise ValueError(f'{name}: expected pixel data')
        intro=sec[:first.start()]
        if '.if 0' in intro:intro=intro.split('.if 0')[0]
        new.append(header+intro+f'\t; 2026 PNG reconstruction: exact original pixel bytes; 1994 label unchanged.\n'
                   +f'\tincbin "build/png_art/{asset_stem(name)}.bin"\n')
    # A generated file, but one with authentic original labels and comments.
    TARGET.write_text(''.join(new),encoding='latin1')
    META.write_text(json.dumps(dict(source='ART_ORIGINAL_1994.S',sprites=manifest),indent=2)+'\n')
    print('Exported/verified',len(manifest),'PNG sprite sources; generated ART.S')
    compile_all()


def compile_all():
    BINARIES.mkdir(parents=True,exist_ok=True)
    if not META.is_file():raise FileNotFoundError('First export PNG sources')
    items=json.loads(META.read_text())['sprites']
    original={name:(info,raw) for name,_,_,info,raw in entries()}
    if len(items)!=len(original):raise ValueError('Sprite manifest outdated')
    changed=[];total=0
    for entry in items:
        name=entry['name'];info,raw=original[name]
        if list(info[:2])!=entry['dimensions'] or info[2]!=entry['encoding'] or sha(raw)!=entry['sha256']:
            raise ValueError(f'{name}: original data or dimensions changed')
        new=from_png(ROOT/entry['png'],info)
        if len(new)!=len(raw):raise ValueError(f'{name}: source image changed byte size')
        (BINARIES/(asset_stem(name)+'.bin')).write_bytes(new)
        total+=len(raw)
        if new!=raw:changed.append(name)
    print(f'Compiled {len(items)} PNG sprites ({total} bytes), edited sprites: {changed}')
    return changed


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=['export','compile'])
    a=p.parse_args()
    if a.command=='export':export()
    else:compile_all()
