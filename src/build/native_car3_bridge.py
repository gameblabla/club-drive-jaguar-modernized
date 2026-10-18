#!/usr/bin/env python3
"""car3: evidence-guarded Car 3 BND quad-fan -> standalone native MDL bridge.

This is a 2026 experimental authoring utility, NOT Atari's original exporter.
It cannot convert the historical two-face merge, arbitrary edits, or runtime
collision/solid-space semantics. Original game inputs are never written.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path

import audit_bnd_to_mdl as lineage
import native_bnd_to_mdl as car2
import native_bnd as bnd
import native_collision as geom
import native_geometry as mdl
import native_tree as tree

SOURCE = Path('CARS/CAR3.BND')
TARGET = Path('CARS/CAR3.MDL')
ROOT = bnd.ROOT
BASE = ROOT/'assets/3d/conversion/car3'


def verified_baseline():
    """Prove the observed one-record deletion and append, not an index heuristic."""
    source=bnd.export_doc(SOURCE)
    target=mdl.export_doc(TARGET)
    evidence=lineage.lineage(SOURCE)
    if (len(source['points']), len(source['normals']), len(source['dividers'])) != (90,31,40):
        raise ValueError('Car3 intermediate inventory changed')
    if (len(target['points']),len(target['normals']),len(target['dividers'])) != (90,31,40):
        raise ValueError('Car3 native inventory changed')
    if [car2.rotate_y(v) for v in source['points']] != target['points']:
        raise ValueError('Car3 native point transform no longer matches')
    converted=[car2.rotate_y(v) for v in source['normals']]
    if target['normals'][:30] != converted[:10]+converted[11:]:
        raise ValueError('Car3 normal deletion/rebase no longer matches')
    if target['normals'][30] != [0,-4874,-32402]:
        raise ValueError('Car3 appended compiled normal changed')
    expected_dividers=source['dividers'][:14]+[
        [p,n-int(n>10)] for p,n in source['dividers'][15:]
    ]+[[12,30]]
    if expected_dividers!=target['dividers'] or source['dividers'][14]!=[12,10]:
        raise ValueError('Car3 divider deletion/shift/replacement not substantiated')
    if (evidence['matched_geometry'],evidence['matched_cyclic_winding'],
        evidence['matched_flags'],evidence['source_polygon_count'],
        evidence['runtime_polygon_count']) != (58,58,58,60,59):
        raise ValueError('Car3 matched-face inventory changed')
    native_faces={car2.key(f):(cp['cp_index'],index,f) for cp in target['cp_lists']
                  for index,f in enumerate(cp['polygons'])}
    if sum(len(x['polygons']) for x in target['cp_lists'])!=len(native_faces):
        raise ValueError('Ambiguous native face vertex sets')
    for row in evidence['face_correspondence']:
        src=source['cp_lists'][row['bnd_group']]['polygons'][row['bnd_face']]
        cp,i,face=native_faces[car2.key(src)]
        if ((cp,i)!=(row['mdl_cp'],row['mdl_face']) or
            not car2.cyclic(src['vertices'],face['vertices']) or
            src['flags']!=face['flags'] or
            face['color']!=src['color']-int(src['color']>10)):
            raise ValueError('Car3 matched polygon conversion has changed')
        if row['source_divider'] != 14:
            expected=row['source_divider']-int(row['source_divider']>14)
            if row['native_divider']!=expected or face['divider']!=expected:
                raise ValueError('Car3 original polygon divider lineage changed')
    merged=evidence['unmatched_runtime_faces']
    if len(merged)!=1 or merged[0]['divider']!=7 or merged[0]['color']!=3:
        raise ValueError('Car3 original merge attributes changed')
    return source,target,evidence


def identify_fan(old,edited,newpoint,newdiv):
    """Match exactly one original quad replaced in-place by four triangles."""
    if len(old['cp_lists'])!=len(edited['cp_lists']):
        raise ValueError('Car3 group count changed')
    changes=[]
    for original_group,group in zip(old['cp_lists'],edited['cp_lists']):
        cp=original_group['cp_index']
        if group.get('cp_index')!=cp:raise ValueError('Car3 source group identity changed')
        before=original_group['polygons'];after=group.get('polygons')
        if not isinstance(after,list):raise ValueError('Car3 polygon list missing')
        if before==after:continue
        if cp==0 or len(after)!=len(before)+3:
            raise ValueError('Exactly one nonempty source quad fan is permitted')
        positions=[]
        for i,f in enumerate(before):
            if len(f['vertices'])!=4 or after[:i]!=before[:i] or after[i+4:]!=before[i+1:]:continue
            verts=f['vertices'];fan=after[i:i+4]
            if all(g.get('flags')==f['flags'] and g.get('color')==f['color']
                   and g.get('divider')==newdiv
                   and car2.cyclic(g.get('vertices'),[verts[j],verts[(j+1)%4],newpoint])
                   for j,g in enumerate(fan)):
                positions.append((i,f))
        if len(positions)!=1:raise ValueError('Unsupported edited Car3 source face')
        changes.append((cp,*positions[0]))
    if len(changes)!=1:raise ValueError('Exactly one Car3 quad must change')
    return changes[0]


def compile_car3(doc):
    source,target,evidence=verified_baseline()
    bnd.validate(SOURCE,doc)
    for k in ('points','normals','dividers'):
        if len(doc[k])!=len(source[k])+1 or doc[k][:len(source[k])]!=source[k]:
            raise ValueError('Car3 bridge permits exactly one appended '+k)
    index=len(doc['points'])  # native polygons use 1-based vertex IDs
    normal_id=len(source['normals'])
    new_divider=len(source['dividers'])
    if doc['dividers'][-1]!=[index-1,normal_id]:
        raise ValueError('Appended divider does not reference new source point/normal')
    cpno,src_index,quad=identify_fan(source,doc,index,new_divider)
    match={(r['bnd_group'],r['bnd_face']):r for r in evidence['face_correspondence']}
    row=match.get((cpno,src_index))
    if row is None or sorted(quad['vertices'])!=row['vertices']:
        raise ValueError('Cannot edit unmatched/merged Car3 source polygons')
    if not all((doc['cp_lists'][cpno]['polygons'][src_index+j]['flags'],
                doc['cp_lists'][cpno]['polygons'][src_index+j]['color'])==
               (quad['flags'],quad['color']) for j in range(4)):
        raise ValueError('Edited polygons lost source attributes')
    original_area=geom.face_area(doc['points'],quad['vertices'])
    newfaces=doc['cp_lists'][cpno]['polygons'][src_index:src_index+4]
    new_area=sum(geom.face_area(doc['points'],f['vertices']) for f in newfaces)
    if abs(original_area-new_area)>1.e-6:
        raise ValueError('Source polygon surface area is not conserved')
    # Avoid topology-flipping normals even when plane-error magnitude is small.
    oldp,oldn=source['dividers'][quad['divider']]
    newnormal=doc['normals'][-1]
    if geom.dot(source['normals'][oldn],newnormal)/(geom.norm(source['normals'][oldn])*geom.norm(newnormal))<0.98:
        raise ValueError('New normal does not preserve original polygon plane orientation')
    generated=copy.deepcopy(target)
    generated['points'].append(car2.rotate_y(doc['points'][-1]))
    generated['normals'].append(car2.rotate_y(newnormal))
    generated['dividers'].append([index-1,len(target['normals'])])
    cpn,ix=row['mdl_cp'],row['mdl_face']
    native_face=generated['cp_lists'][cpn]['polygons'][ix]
    if (car2.key(native_face)!=car2.key(quad) or
        not car2.cyclic(quad['vertices'],native_face['vertices']) or
        native_face['color']!=quad['color']-int(quad['color']>10)):
        raise ValueError('Unsafe target Car3 CP/material mapping')
    nv=native_face['vertices'];fan=[]
    for j,v in enumerate(nv):
        f=copy.deepcopy(native_face)
        f['vertices']=[v,nv[(j+1)%4],index]
        f['divider']=len(target['dividers'])
        fan.append(f)
    generated['cp_lists'][cpn]['polygons'][ix:ix+1]=fan
    assembled,stats=mdl.compile_text(TARGET,generated)
    redecoded=tree.native_layout(TARGET,assembled)
    baseline=tree.native_layout(TARGET)
    if (len(redecoded['nodes'])!=len(baseline['nodes']) or
        redecoded['polygons']!=baseline['polygons']+3):
        raise ValueError('Unexpected native Car3 tree or face inventory')
    for i,(before,after) in enumerate(zip(target['cp_lists'],generated['cp_lists'])):
        if i!=cpn and before!=after:
            raise ValueError('Unedited Car3 runtime leaf changed')
    stats.update(source=str(SOURCE),native_target=str(TARGET),
        source_group=cpno,source_index=src_index,runtime_cp=cpn,runtime_index=ix,
        original_area=original_area,edited_area=new_area,area_error=abs(original_area-new_area),
        verified_unedited_correspondence=58,original_merged_faces_preserved=True,
        original_tree_node_count=len(baseline['nodes']),
        link_into_game=False,scope='Standalone source-to-native geometry authoring only')
    return assembled,generated,stats


def make_probe():
    src=bnd.export_doc(SOURCE)
    cpno,fi=1,1
    quad=src['cp_lists'][cpno]['polygons'][fi]
    if quad['vertices']!=[5,8,7,6]:raise ValueError('Car3 demonstration quad changed')
    p=src['points'];v=quad['vertices']
    position=[round((p[v[0]-1][j]+p[v[2]-1][j])/2) for j in range(3)]
    p.append(position);point=len(p)
    normal_raw=geom.cross(geom.sub(p[v[1]-1],p[v[0]-1]),geom.sub(p[v[2]-1],p[v[1]-1]))
    normal=[round(x*32767/geom.norm(normal_raw)) for x in normal_raw]
    src['normals'].append(normal)
    divider=len(src['dividers'])
    src['dividers'].append([point-1,len(src['normals'])-1])
    fan=[]
    for j,x in enumerate(v):
        f=copy.deepcopy(quad);f['vertices']=[x,v[(j+1)%4],point];f['divider']=divider
        fan.append(f)
    src['cp_lists'][cpno]['polygons'][fi:fi+1]=fan
    source_blob,source_stats=bnd.compile_text(SOURCE,src)
    blob,geometry,stats=compile_car3(src)
    d=BASE/'probes';d.mkdir(parents=True,exist_ok=True)
    outputs={'CAR3_edited.BND':source_blob,
             'CAR3_edited.geometry.json':(json.dumps(src,indent=2)+'\n').encode(),
             'CAR3_from_BND.MDL':blob,
             'CAR3_runtime.geometry.json':(json.dumps(geometry,indent=2)+'\n').encode()}
    for name,data in outputs.items():(d/name).write_bytes(data)
    stats.update(source_bnd_sha256=hashlib.sha256(source_blob).hexdigest(),
                 native_mdl_sha256=hashlib.sha256(blob).hexdigest(),
                 source_added_edges=source_stats['new_edges'],
                 output_hashes={name:hashlib.sha256(data).hexdigest() for name,data in outputs.items()},
                 new_source_point=position,new_native_point=car2.rotate_y(position))
    (d/'probe.json').write_text(json.dumps(stats,indent=2)+'\n')
    return stats


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('action',choices=['baseline','probe','check'])
    args=ap.parse_args()
    if args.action=='baseline':
        src,dst,rows=verified_baseline()
        print('Car3: 58 original faces; 40 mapped native dividers; 1 source face-merge exception')
        return
    if args.action=='check':
        folder=BASE/'probes'
        names={'CAR3_edited.BND','CAR3_edited.geometry.json','CAR3_from_BND.MDL','CAR3_runtime.geometry.json','probe.json'}
        if not all((folder/n).is_file() for n in names):raise ValueError('Missing Car3 car3 probe artifacts')
        saved={n:(folder/n).read_bytes() for n in names}
        stats=make_probe()
        if saved!={n:(folder/n).read_bytes() for n in names}:
            raise ValueError('Car3 probe is stale or nondeterministic')
    else:
        stats=make_probe()
    print(json.dumps(stats,indent=2))

if __name__=='__main__':main()
