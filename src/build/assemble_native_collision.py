#!/usr/bin/env python3
"""POLYGONS RMAC binary proof for unlinked Car 2 native quad split.

The original .MDL and edited .MDL are assembled with the Jaguar SDK; this
script checks the actual output bytes, not just the Python source emitter.
No retail-ROM replacement or runtime collision claim is made.
"""
from asset_paths import asset_file
import argparse
import hashlib
import json
import struct
import subprocess
import tempfile
from pathlib import Path
import native_collision as nc
import native_tree as nt

OUTPUT=nc.BASE/'probes'/'assembly_validation.json'

def word(data,offset):return struct.unpack_from('>H',data,offset)[0]
def longword(data,offset):return struct.unpack_from('>I',data,offset)[0]

def check(rmac):
    rmac=Path(rmac).resolve()
    if not rmac.is_file():raise FileNotFoundError(rmac)
    rel=Path('CAR2.MDL')
    stat=nc.split_quad_probe()
    original=asset_file(rel)
    edited=nc.BASE/'probes'/'CAR2_split_quad.MDL'
    lo=nt.native_layout(rel)
    ln=nt.native_layout(rel,edited.read_bytes())
    if stat['added_edges']!=1 or stat['cp_delta_bytes']!=10 or stat['tree_delta_bytes']!=16:
        raise ValueError('Unrecognized Car 2 proof mutation')
    with tempfile.TemporaryDirectory(prefix='club_assembler_') as temporary:
        original_bin=Path(temporary)/'old.bin';edited_bin=Path(temporary)/'edit.bin'
        for src,dest in ((original,original_bin),(edited,edited_bin)):
            proc=subprocess.run([str(rmac),'-fb','-u','-o',str(dest),str(src)],
                                cwd=nc.ROOT,text=True,capture_output=True,timeout=45)
            if proc.returncode!=0 or not dest.exists():
                raise RuntimeError(f'Jaguar RMAC failed to assemble {src}: {proc.stderr}\n{proc.stdout}')
        before=original_bin.read_bytes();after=edited_bin.read_bytes()
    if len(before)!=2920 or len(after)!=2936:raise ValueError('Unexpected assembled byte sizes')
    if word(before,42)!=143 or word(after,42)!=144:
        raise ValueError('Native 16-bit edge count not updated')
    # RMAC -fb prepends a 32-byte binary header; cross-check native data
    # position against both the assembled pointer and an independent signature.
    sig=struct.pack('>HHHH',3,0,4,1)
    base=before.find(sig)
    if base<0 or base!=after.find(sig) or base!=longword(before,68)+32 or base!=156:
        raise ValueError('Native data base not found at expected binary offset')
    oldp={k:v['number'] for k,v in lo['header_pointers'].items()}
    newp={k:v['number'] for k,v in ln['header_pointers'].items()}
    for key,offset in [('dividers',68),('edges',72),('points',76),('tris',80),
                       ('end of tris',84),('tree',88),('calculated colors',96)]:
        if longword(before,offset)!=longword(before,68)+oldp[key] or longword(after,offset)!=longword(after,68)+newp[key]:
            raise ValueError(f'RMAC header pointer relocation differs: {key}')
    if before[base:base+oldp['points']]!=after[base:base+oldp['points']]:
        raise ValueError('Native original dividers/edges differ')
    edges,vertices,normals,divs=nc.source_geometry(rel)
    original_first=nc.original_cp(rel)[1]['polygons'][0]
    verts=original_first['vertices']
    appended=(verts[2],verts[0])
    if after[base+oldp['points']:base+oldp['points']+4]!=struct.pack('>HH',*appended):
        raise ValueError('New diagonal is not the expected native 1-based vertex pair')
    if before[base+oldp['points']:base+oldp['tris']]!=after[base+newp['points']:base+newp['tris']]:
        raise ValueError('Jaguar native points or normal vectors changed')
    original_cps=before[base+oldp['tris']:base+oldp['tris']+lo['cp_bytes']]
    edited_cps=after[base+newp['tris']:base+newp['tris']+ln['cp_bytes']]
    # Original first CP is the 2-byte background zero, then a 14-byte quad.
    # Two six-word triangles replace that quad; every *other* CP byte stays.
    if not(original_cps[:2]==edited_cps[:2]==b'\0\0' and
           original_cps[16:]==edited_cps[26:]):
        raise ValueError('Unedited native CP polygons changed')
    i=oldp['tris']
    original_quad=list(struct.unpack_from('>7H',original_cps,2))
    first=list(struct.unpack_from('>6H',edited_cps,2))
    second=list(struct.unpack_from('>6H',edited_cps,14))
    if first[:2]!=[original_quad[0]-1,original_quad[1]] or second[:2]!=[original_quad[0]-1,original_quad[1]]:
        raise ValueError('Divider or polygon surface flags changed during split')
    if first[2:5]!=[original_quad[2],original_quad[3],len(edges)]:
        raise ValueError('First new triangle has incorrect directed edges')
    if second[2:5]!=[len(edges)|0x8000,original_quad[4],original_quad[5]]:
        raise ValueError('Second new triangle has incorrect directed edges')
    if first[-1]!=second[-1] or first[-1]!=original_quad[-1]:
        raise ValueError('Material was not preserved')
    # Tree remains three nodes. Only CP2 leaf offset changes by +10.
    ot=before[base+oldp['tree']:base+oldp['calculated colors']]
    et=after[base+newp['tree']:base+newp['calculated colors']]
    if len(ot)!=len(et) or ot[:20]!=et[:20] or longword(et,20)!=longword(ot,20)+10:
        raise ValueError('BSP leaf rebasing failed in machine code')
    tail_before=before[base+oldp['calculated colors']:]
    tail_after=after[base+newp['calculated colors']:]
    if tail_before!=tail_after:raise ValueError('Original native color/tail section changed')
    stats={'scope':'standalone Jaguar RMAC model binary only; NOT game collision parity',
           'rmac_success':True,'original_size_bytes':len(before),'edited_size_bytes':len(after),
           'size_increase_bytes':len(after)-len(before),'added_edges':1,
           'added_triangles_net':1,'cp_bytes_added':10,'tree_relocation_bytes':16,
           'rebound_second_cp_offset':[676,686],
           'unaltered_post_tree_bytes':len(tail_before),'original_sha256':hashlib.sha256(before).hexdigest(),
           'modified_sha256':hashlib.sha256(after).hexdigest(),
           'area_conservation_error':stat['area_conservation_error'],
           'point_normal_arrays_identical':True,'untouched_cp_payload_identical':True,
           'untouched_color_payload_identical':True}
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    OUTPUT.write_text(json.dumps(stats,indent=2)+'\n')
    return stats

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rmac',required=True)
    args=p.parse_args()
    print(json.dumps(check(args.rmac),indent=2))
