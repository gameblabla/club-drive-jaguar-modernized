#!/usr/bin/env python3
"""Independent RMAC byte-section audit for the car3 standalone Car 3 experiment."""
import argparse
import hashlib
import json
import struct
import subprocess
import tempfile
from pathlib import Path
from asset_paths import asset_file

import native_car3_bridge as bridge
import native_tree as tree
from assemble_bnd_bridge import section

OUT=bridge.BASE/'probes/assembly_validation.json'

def proof(rmac):
    if not Path(rmac).is_file():raise FileNotFoundError(rmac)
    stats=bridge.make_probe()
    original=tree.native_layout(bridge.TARGET)
    edited=tree.native_layout(bridge.TARGET,(bridge.BASE/'probes/CAR3_from_BND.MDL').read_bytes())
    with tempfile.TemporaryDirectory(prefix='club_car3_rmac_') as tmp:
        binaries=[]
        for name,source in [('original',asset_file(bridge.TARGET)),
                            ('experimental',bridge.BASE/'probes/CAR3_from_BND.MDL')]:
            target=Path(tmp)/(name+'.o')
            command=[str(Path(rmac).resolve()),'-fb','-u','-o',str(target),str(source)]
            done=subprocess.run(command,cwd=bridge.ROOT,text=True,capture_output=True,timeout=45)
            if done.returncode or not target.exists():
                raise RuntimeError('RMAC rejected Car3 native model: '+done.stdout+done.stderr)
            binaries.append(section(target.read_bytes()))
    a,b=binaries
    ba=struct.unpack_from('>I',a,36)[0]
    bb=struct.unpack_from('>I',b,36)[0]
    if ba!=bb or ba!=124:raise ValueError('Unexpected native object section data base')
    x={k:v['number'] for k,v in original['header_pointers'].items()}
    y={k:v['number'] for k,v in edited['header_pointers'].items()}
    u=original['header_counts'];v=edited['header_counts']
    if {k:v[k]-u[k] for k in ('NUM_PNTS','NUM_VECTORS','NUM_DIVIDERS','NUM_EDGES','NUM_CPS','NUM_COLORS')}!={
        'NUM_PNTS':1,'NUM_VECTORS':1,'NUM_DIVIDERS':1,'NUM_EDGES':4,'NUM_CPS':0,'NUM_COLORS':0}:
        raise ValueError('Native header table growth mismatched')
    get=lambda buf,base,position,count:buf[base+position:base+position+count]
    for key,sz in [('dividers',4*u['NUM_DIVIDERS']),('edges',4*u['NUM_EDGES']),
                   ('points',6*u['NUM_PNTS'])]:
        if get(a,ba,x[key],sz)!=get(b,bb,y[key],sz):
            raise ValueError('Original native table changed: '+key)
    old_normals=x['points']+6*u['NUM_PNTS']
    new_normals=y['points']+6*v['NUM_PNTS']
    if get(a,ba,old_normals,6*u['NUM_VECTORS'])!=get(b,bb,new_normals,6*u['NUM_VECTORS']):
        raise ValueError('Original Car3 native normal values changed')
    if get(b,bb,y['edges']-4,4)!=struct.pack('>HH',90,31):
        raise ValueError('Appended native divider is not point 90, normal 31')
    if get(b,bb,y['points']+6*u['NUM_PNTS'],6)!=struct.pack('>hhh',0,20,-36):
        raise ValueError('Edited point Y-axis transform incorrect')
    if get(b,bb,new_normals+6*u['NUM_VECTORS'],6)!=struct.pack('>hhh',0,32767,0):
        raise ValueError('Edited normal Y-axis transform incorrect')
    for pair in struct.iter_unpack('>HH',get(b,bb,y['points']-16,16)):
        if min(pair)<1 or max(pair)>91:raise ValueError('New native directed edge is out of range')
    original_cp=get(a,ba,x['tris'],original['cp_bytes'])
    edited_cp=get(b,bb,y['tris'],edited['cp_bytes'])
    if original_cp[:2]!=edited_cp[:2] or original_cp[16:]!=edited_cp[50:]:
        raise ValueError('Untouched original Car3 polygons or CP0 terminator changed')
    if edited['cp_bytes']-original['cp_bytes']!=34:
        raise ValueError('Unexpected changed Car3 polygon data length')
    orig_nodes=get(a,ba,x['tree'],len(original['nodes'])*8)
    edit_nodes=get(b,bb,y['tree'],len(edited['nodes'])*8)
    expected=bytearray(orig_nodes)
    for i,n in enumerate(original['nodes']):
        if n['type']=='leaf':
            new_offset=next(r['offset'] for r in edited['cp_records'] if r['index']==
                            next(r['index'] for r in original['cp_records'] if r['offset']==n['cp_offset']))
            struct.pack_into('>I',expected,8*i+4,new_offset)
    if bytes(expected)!=edit_nodes:
        raise ValueError('Native split records, node type, flags or leaf pointer mismatch')
    tail_a=get(a,ba,x['calculated colors'],len(a)-ba-x['calculated colors'])
    tail_b=get(b,bb,y['calculated colors'],len(b)-bb-y['calculated colors'])
    if not tail_a or tail_a!=tail_b:
        raise ValueError('Post-tree Car3 color payload changed')
    if a[16:36]!=b[16:36]:raise ValueError('Original Car3 radius/origin changed')
    if len(b)-len(a)!=68 or y['calculated colors']-x['calculated colors']!=68:
        raise ValueError('Expected full Car3 model growth is 68 bytes')
    result={'scope':'Separate RMAC-accepted standalone Car3 MDL, not a modified game ROM',
        'rmac_accepted_original_and_generated':True,'baseline_binary_bytes':len(a),
        'edited_binary_bytes':len(b),'growth_bytes':len(b)-len(a),
        'old_cp_offsets':{r['index']:r['offset'] for r in original['cp_records']},
        'new_cp_offsets':{r['index']:r['offset'] for r in edited['cp_records']},
        'original_bsp_nodes':len(original['nodes']),
        'color_payload_bytes':len(tail_a),
        'original_binary_sha256':hashlib.sha256(a).hexdigest(),
        'generated_binary_sha256':hashlib.sha256(b).hexdigest()}
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--rmac',required=True)
    args=parser.parse_args()
    print(json.dumps(proof(args.rmac),indent=2))
