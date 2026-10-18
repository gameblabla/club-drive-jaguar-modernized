#!/usr/bin/env python3
"""2026 conversion of original 3D Studio/Targa artist files to PNG.

This is an interchange/export step, NOT the lost Atari TGA-to-CRY compiler.
For transparency the source TGA byte-for-byte archive is saved separately.
No TGA is required for compiling ART.S or the recovered cartridge resources.
"""
import argparse,hashlib,json,tarfile
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
PICS=ROOT/'assets/graphics/ui'
ARCH=ROOT/'assets/native/graphics/archive'

def run():
    original=sorted(p for p in PICS.iterdir() if p.suffix.lower()=='.tga')
    if not original:
        print('PICS already contains PNGs (no TGA to convert)')
        return
    grouped={}
    for p in original: grouped.setdefault(p.stem.upper(),[]).append(p)
    ARCH.mkdir(exist_ok=True)
    log=[]
    for stem,sources in sorted(grouped.items()):
        with Image.open(sources[0]) as im:
            # All 42 original images are RGB truecolor (no lossy 8-bit palette conversion).
            rgb=im.convert('RGB')
            path=PICS/(stem+'.png')
            if not path.exists():rgb.save(path,'PNG',optimize=True)
            with Image.open(path) as test:
                if test.mode!='RGB' or test.size!=rgb.size or test.tobytes()!=rgb.tobytes():
                    raise ValueError(f'PNG pixel roundtrip failed: {stem}')
            hashes=[]
            for src in sources:
                with Image.open(src) as old:
                    if old.size!=rgb.size or old.convert('RGB').tobytes()!=rgb.tobytes():
                        raise ValueError(f'Case-sensitive TGA duplicate has different pixels: {src}')
                hashes.append({'file':src.name,'sha256':hashlib.sha256(src.read_bytes()).hexdigest()})
            log.append({'png':f'assets/graphics/ui/{path.name}','width':rgb.width,'height':rgb.height,'mode':'RGB',
                        'source_tga':hashes,'png_sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (ARCH/'tga_to_png_index.json').write_text(json.dumps({'note':'Pixel-identical PNG conversions; archive preserves TGA original bytes', 'images':log},indent=2)+'\n')
    with tarfile.open(ARCH/'original_artist_tga.tar.gz','w:gz') as tar:
        for src in original:tar.add(src,arcname='assets/graphics/ui/'+src.name)
    for src in original:src.unlink()
    print(f'Converted {len(grouped)} unique TGA images ({len(original)} archival file aliases) to RGB PNG; archived originals')

if __name__=='__main__':run()
