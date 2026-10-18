#!/usr/bin/env python3
"""Assemble and byte-audit isolated Jaguar-native Car 2 full-table edit (not a ROM)."""
from asset_paths import asset_file
import argparse
import hashlib
import json
import struct
import subprocess
import tempfile
from pathlib import Path
import native_geometry as geom
import native_tree as nt

OUTPUT=geom.BASE/'probes'/'assembly_validation.json'
def u16(data,i):return struct.unpack_from('>H',data,i)[0]
def u32(data,i):return struct.unpack_from('>I',data,i)[0]
def check(rmac):
    rm=Path(rmac).resolve()
    if not rm.is_file():raise FileNotFoundError(rm)
    rel=Path('CAR2.MDL');stats=geom.geometry_probe()
    original=asset_file(rel)
    modified=geom.BASE/'probes'/'CAR2_full_tables.MDL'
    oldlayout=nt.native_layout(rel);newlayout=nt.native_layout(rel,modified.read_bytes())
    with tempfile.TemporaryDirectory(prefix='club_asm_') as tmp:
        temp=Path(tmp);oldbinary=temp/'original.bin';newbinary=temp/'edited.bin'
        for src,dst in ((original,oldbinary),(modified,newbinary)):
            proc=subprocess.run([str(rm),'-fb','-u','-o',str(dst),str(src)],
                cwd=geom.ROOT,capture_output=True,text=True,timeout=45)
            if proc.returncode or not dst.exists():
                raise RuntimeError('RMAC refused native input: '+proc.stderr+'\n'+proc.stdout)
        before=oldbinary.read_bytes();after=newbinary.read_bytes()
    old={k:v['number'] for k,v in oldlayout['header_pointers'].items()}
    new={k:v['number'] for k,v in newlayout['header_pointers'].items()}
    base=u32(before,68)+32
    if base!=156 or u32(after,68)+32!=base:raise ValueError('Assembled native data base not stable')
    for key,at in [('dividers',68),('edges',72),('points',76),('tris',80),
                   ('end of tris',84),('tree',88),('calculated colors',96)]:
        if u32(before,at)!=u32(before,68)+old[key] or u32(after,at)!=u32(after,68)+new[key]:
            raise ValueError(f'{key}: assembled pointer does not match authored relocation')
    for offset,b,a in [(36,94,95),(38,31,32),(40,54,55),(42,143,147)]:
        if u16(before,offset)!=b or u16(after,offset)!=a:
            raise ValueError(f'Header count at {offset} incorrect')
    if before[base:base+old['edges']]!=after[base:base+old['edges']]:
        raise ValueError('Original dividers mutated')
    if after[base+old['edges']:base+new['edges']]!=struct.pack('>HH',94,31):
        raise ValueError('New divider not assembled correctly')
    if before[base+old['edges']:base+old['points']]!=after[base+new['edges']:base+new['edges']+old['points']-old['edges']]:
        raise ValueError('Original edges mutated')
    origedges=old['points']-old['edges']
    if new['points']-new['edges'] != origedges+16:raise ValueError('Four expected new edges missing')
    if before[base+old['points']:base+old['points']+94*6]!=after[base+new['points']:base+new['points']+94*6]:
        raise ValueError('Original native points changed')
    if after[base+new['points']+94*6:base+new['points']+95*6]!=struct.pack('>hhh',0,20,-36):
        raise ValueError('New point incorrectly encoded')
    old_norm_at=old['points']+94*6
    new_norm_at=new['points']+95*6
    if before[base+old_norm_at:base+old['tris']]!=after[base+new_norm_at:base+new_norm_at+31*6]:
        raise ValueError('Original native normals changed')
    if after[base+new_norm_at+31*6:base+new['tris']]!=struct.pack('>hhh',0,32767,0):
        raise ValueError('New native normal incorrectly encoded')
    oldcp=before[base+old['tris']:base+old['tris']+oldlayout['cp_bytes']]
    newcp=after[base+new['tris']:base+new['tris']+newlayout['cp_bytes']]
    if not (oldcp[:2]==newcp[:2]==b'\0\0' and oldcp[16:]==newcp[50:]):
        raise ValueError('Unchanged CP payload changed')
    cpfirst=struct.unpack_from('>6H',newcp,2)
    if cpfirst[0]!=0x2003 or cpfirst[1]!=54:
        raise ValueError('New first triangle does not reference new divider')
    oldtree=before[base+old['tree']:base+old['calculated colors']]
    newtree=after[base+new['tree']:base+new['calculated colors']]
    if len(oldtree)!=24 or len(newtree)!=24 or oldtree[:20]!=newtree[:20] or u32(newtree,20)!=u32(oldtree,20)+34:
        raise ValueError('Leaf relocation or original split changed')
    tail=before[base+old['calculated colors']:]
    if tail!=after[base+new['calculated colors']:]:
        raise ValueError('Post-tree colors/tail changed')
    if len(after)-len(before)!=68:raise ValueError('Assembled size delta unexpected')
    result={'scope':'Isolated standalone RMAC car MDL only; no game ROM or gameplay validation',
        'assembler_pass':True,'old_bytes':len(before),'new_bytes':len(after),
        'size_delta_bytes':len(after)-len(before),'new_point':stats['new_point'],
        'new_normal':stats['new_normal'],'new_divider':stats['new_divider'],
        'added_edges':stats['added_edges'],'triangles_replacing_quad':4,
        'cp_delta_bytes':stats['cp_delta_bytes'],'tree_relocation_bytes':stats['tree_delta_bytes'],
        'new_cp2_offset':stats['cp_offsets'][2],
        'retained_post_tree_bytes':len(tail),'surface_area_error':stats['probe_area_error'],
        'original_assembled_sha256':hashlib.sha256(before).hexdigest(),
        'edited_assembled_sha256':hashlib.sha256(after).hexdigest()}
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    OUTPUT.write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rmac',required=True)
    args=p.parse_args();print(json.dumps(check(args.rmac),indent=2))
