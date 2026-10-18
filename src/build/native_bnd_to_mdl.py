#!/usr/bin/env python3
"""car2: guarded BND->native MDL bridge for source-grounded CAR2 quad fan.

A 2026 reconstruction, NOT Atari's missing BND2MDL compiler. Only the
original Car 2 intermediary/compiled pair has verified one-to-one geometry,
normal, divider, color, and BSP leaf membership. Changed geometry is emitted
as a separate MDL: no retail or game runtime file is written.
"""
import argparse, copy, hashlib, json
from collections import Counter
from pathlib import Path

import native_bnd as bnd
import native_collision as geom
import native_geometry as native
import native_model_pipeline as model
import native_tree as tree

ROOT=bnd.ROOT
BASE=ROOT/'assets/3d/conversion/car2'
CAR2_BND=Path('CARS/CAR2.BND')
CAR2_MDL=Path('CARS/CAR2.MDL')

def rotate_y(p):return [-p[0],p[1],-p[2]]
def key(face):return tuple(sorted(face['vertices']))
def cyclic(v,other):return len(v)==len(other) and any(v==other[j:]+other[:j] for j in range(len(v)))

def face_table(rel):
    doc=native.export_doc(rel)
    return {key(f):(cp['cp_index'],i,f) for cp in doc['cp_lists'] for i,f in enumerate(cp['polygons'])}

def exact_car2_baseline():
    source=bnd.export_doc(CAR2_BND)
    mdl=native.export_doc(CAR2_MDL)
    if ([rotate_y(p) for p in source['points']]!=mdl['points'] or
        [rotate_y(p) for p in source['normals']]!=mdl['normals'] or
        source['dividers']!=mdl['dividers']):
        raise ValueError('Car2 geometry/normal/divider provenance changed')
    srcfaces=[(c['cp_index'],f) for c in source['cp_lists'] for f in c['polygons']]
    destfaces={key(f):(c['cp_index'],f) for c in mdl['cp_lists'] for f in c['polygons']}
    if len(destfaces)!=len(srcfaces) or len(destfaces)!=60:
        raise ValueError('Car2 has duplicate/missing runtime face IDs')
    for group,f in srcfaces:
        if key(f) not in destfaces:raise ValueError('Car2 BND face missing in MDL')
        cp,t=destfaces[key(f)]
        if (group!=cp or (f['flags'],f['divider'],f['color'])!=(t['flags'],t['divider'],t['color'])
            or not cyclic(f['vertices'],t['vertices'])):
            raise ValueError('Car2 source face differs from runtime leaf or attributes')
    return source,mdl

def locate_quad_fan(before,after,old_point,new_div):
    """Recognize precisely one original quad replaced by a four-triangle fan."""
    changes=[]
    for c,edited in zip(before['cp_lists'],after['cp_lists']):
        old=c['polygons'];new=edited['polygons']
        if old==new:continue
        if c['cp_index'] not in (1,2) or len(new)!=len(old)+3:
            raise ValueError('Only one non-background quad-to-four-triangle fan is supported')
        candidates=[]
        for i,face in enumerate(old):
            if new[:i]!=old[:i] or new[i+4:]!=old[i+1:]:continue
            if len(face['vertices'])!=4:continue
            loop=face['vertices'];expected=[(loop[j],loop[(j+1)%4],old_point) for j in range(4)]
            actual=new[i:i+4]
            if all((f['flags'],f['color'],f['divider'])==(face['flags'],face['color'],new_div)
                   and len(f['vertices'])==3 and cyclic(f['vertices'],list(tri))
                   for f,tri in zip(actual,expected)):
                candidates.append((i,face))
        if len(candidates)!=1:raise ValueError('Cannot uniquely identify a native fan replacement')
        changes.append((c['cp_index'],*candidates[0]))
    if len(changes)!=1:raise ValueError('Exactly one quad fan must be changed')
    return changes[0]

def compile_car2(doc):
    original,original_mdl=exact_car2_baseline()
    bnd.validate(CAR2_BND,doc)
    # Editing preexisting source tables, materials, unrelated polygons, or
    # CP ownership is intentionally unsupported by this bridge.
    for name in ('points','normals','dividers'):
        if doc[name][:len(original[name])]!=original[name] or len(doc[name])!=len(original[name])+1:
            raise ValueError('Car2 bridge only permits one appended '+name)
    point_id=len(original['points'])+1
    normal_id=len(original['normals'])
    div_id=len(original['dividers'])
    if doc['dividers'][-1]!=[point_id-1,normal_id]:
        raise ValueError('New divider must refer to appended point and normal')
    if len(doc['cp_lists'])!=len(original['cp_lists']):raise ValueError('Changed source CP layout')
    for old,now in zip(original['cp_lists'],doc['cp_lists']):
        if now.get('cp_index')!=old['cp_index']:raise ValueError('Changed source CP ownership')
    cpno,src_index,old_quad=locate_quad_fan(original,doc,point_id,div_id)
    if abs(geom.face_area(doc['points'],old_quad['vertices'])-
           sum(geom.face_area(doc['points'],f['vertices']) for f in doc['cp_lists'][cpno]['polygons'][src_index:src_index+4]))>1.e-6:
        raise ValueError('BND fan area not conserved')
    out=copy.deepcopy(original_mdl)
    out['points']=[rotate_y(p) for p in doc['points']]
    out['normals']=[rotate_y(n) for n in doc['normals']]
    out['dividers']=copy.deepcopy(doc['dividers'])
    match=face_table(CAR2_MDL)
    if key(old_quad) not in match:raise ValueError('BND polygon is absent from original compiled geometry')
    mdl_cp,mdl_index,model_quad=match[key(old_quad)]
    if mdl_cp!=cpno:raise ValueError('Car2 BND/MDL CP leaf mismatch')
    runtime_loop=model_quad['vertices']
    fan=[]
    for j,a in enumerate(runtime_loop):
        face=copy.deepcopy(model_quad)
        face['vertices']=[a,runtime_loop[(j+1)%4],point_id]
        face['divider']=div_id
        fan.append(face)
    out['cp_lists'][mdl_cp]['polygons'][mdl_index:mdl_index+1]=fan
    blob,stats=native.compile_text(CAR2_MDL,out)
    # Independent decoder: ensure every retained runtime polygon is unchanged,
    # and every generated triangle appears exactly once in the assigned leaf.
    check=tree.native_layout(CAR2_MDL,blob)
    if check['polygons']!=63 or len(check['nodes'])!=3:
        raise ValueError('Runtime collision tree/face count differs from intended probe')
    new_cp=check['cp_records'][mdl_cp]
    old_cp=tree.native_layout(CAR2_MDL)['cp_records'][mdl_cp]
    if new_cp['offset']!=old_cp['offset']:
        raise ValueError('Target leaf moved when only its contents should grow')
    stats.update(source='CARS/CAR2.BND',native_target=str(CAR2_MDL),source_group=cpno,
        source_face_index=src_index,native_face_index=mdl_index,
        face_area_error=0.0,verified_original_face_correspondence=60,
        editable_source='BND JSON',link_into_game=False)
    return blob,out,stats

def make_probe():
    edited=json.loads((bnd.BASE/'probes/CAR2_edited.geometry.json').read_text())
    blob,doc,stats=compile_car2(edited)
    out=BASE/'probes';out.mkdir(parents=True,exist_ok=True)
    (out/'CAR2_from_BND.MDL').write_bytes(blob)
    (out/'CAR2_runtime.geometry.json').write_text(json.dumps(doc,indent=2)+'\n')
    stats.update(output_sha256=hashlib.sha256(blob).hexdigest(),source_bnd_probe_hash=hashlib.sha256((bnd.BASE/'probes/CAR2_edited.BND').read_bytes()).hexdigest())
    (out/'bridge_probe.json').write_text(json.dumps(stats,indent=2)+'\n')
    return stats

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('command',choices=['baseline','probe','check'])
    args=ap.parse_args()
    if args.command=='baseline':
        source,mdl=exact_car2_baseline();print('CAR2 exact origin/table/CP match:',sum(len(x['polygons']) for x in mdl['cp_lists']),'faces');return
    if args.command=='check':
        prior=(BASE/'probes/bridge_probe.json').read_bytes()
        md=(BASE/'probes/CAR2_from_BND.MDL').read_bytes()
        now=make_probe()
        if (BASE/'probes/bridge_probe.json').read_bytes()!=prior or (BASE/'probes/CAR2_from_BND.MDL').read_bytes()!=md:
            raise ValueError('Stale/non-reproducible car2 native bridge output')
    else:now=make_probe()
    print(json.dumps(now,indent=2))

if __name__=='__main__':main()
