#!/usr/bin/env python3
"""car2 face-by-face evidence: BND intermediate to MDL runtime CP leaf attribution.

Mappings are observed in surviving Atari model data. They do not establish
BSP solid/empty semantics or reimplement historical compilation.
"""
from asset_paths import asset_file
import argparse, json
from collections import Counter, defaultdict
from pathlib import Path
import native_bnd as bnd
import native_collision as collision
import native_model_pipeline as model
import native_tree as tree

BASE=bnd.ROOT/'assets/3d/conversion/car2'
OUTPUT=BASE/'face_lineage.json'

def face_key(f):return tuple(sorted(f['vertices']))
def cyclic(x,y):return len(x)==len(y) and any(x==y[i:]+y[:i] for i in range(len(x)))

def runtime_faces(rel):
    parsed=model.scan(asset_file(rel).read_text(),'MDL')
    edges=[r['values'] for r in parsed if r['group']=='edges']
    layout=tree.native_layout(rel)
    result=[]
    for cp in layout['cp_records']:
        i=0;w=cp['words'];fidx=0
        while i<len(w)-1:
            size=(w[i]&15)+3
            f=collision.decode_face(w[i:i+size],edges)
            result.append({'cp':cp['index'],'index':fidx,**f})
            fidx+=1;i+=size
        if i!=len(w)-1:raise ValueError('Bad native face lengths')
    return layout,result

def lineage(rel):
    data=bnd.decode(bnd.original(rel));native=rel.with_suffix('.MDL')
    layout,faces=runtime_faces(native)
    originals=[{'group':g['cp_index'],'index':i,**f} for g in data['cp_lists'] for i,f in enumerate(g['polygons'])]
    src={face_key(f):f for f in originals}
    dst={face_key(f):f for f in faces}
    if len(src)!=len(originals) or len(dst)!=len(faces):raise ValueError('Duplicate face vertex identity')
    common=src.keys() & dst.keys()
    rows=[];matrix=Counter();flags=0;cyclic_count=0;material_equal=0
    for k in sorted(common):
        a=src[k];b=dst[k];matrix[(a['group'],b['cp'])]+=1
        flags+=a['flags']==b['flags'];cyclic_count+=cyclic(a['vertices'],b['vertices'])
        material_equal+=(a['color']==b['color'] and a['flags']==b['flags'])
        rows.append({'vertices':list(k),'bnd_group':a['group'],'bnd_face':a['index'],
                     'mdl_cp':b['cp'],'mdl_face':b['index'],
                     'source_divider':a['divider'],'native_divider':b['divider'],
                     'source_color':a['color'],'native_color':b['color'],
                     'same_winding':cyclic(a['vertices'],b['vertices']),
                     'same_polygon_flags':a['flags']==b['flags']})
    src_only=[src[k] for k in sorted(src.keys()-common)];dst_only=[dst[k] for k in sorted(dst.keys()-common)]
    return {'source':str(rel),'runtime':str(native),
            'source_polygon_count':len(originals),'runtime_polygon_count':len(faces),
            'matched_geometry':len(common),'matched_flags':flags,'matched_cyclic_winding':cyclic_count,
            'matched_flags_and_material':material_equal,
            'source_group_to_runtime_leaf':[
                {'bnd_group':x,'mdl_cp':y,'polygons':count} for (x,y),count in sorted(matrix.items())],
            'unmatched_source_faces':src_only,'unmatched_runtime_faces':dst_only,
            'runtime_tree_leaves':len([n for n in layout['nodes'] if n['type']=='leaf']),
            'runtime_tree_nodes':len(layout['nodes']),
            'face_correspondence':rows}

def car3_findings(leaf):
    rel=bnd.MODELS[1];base=bnd.decode(bnd.original(rel))
    mdl=rel.with_suffix('.MDL')
    original_rows=model.scan((asset_file(mdl)).read_text(),'MDL')
    normals=[row['values'] for row in original_rows if row['group']=='normals']
    transformed=[[-a,b,-c] for a,b,c in base['normals']]
    if len(normals)!=31 or normals[:30]!=transformed[:10]+transformed[11:]:
        raise ValueError('Car3 normal deletion/shift no longer matches evidence')
    if len(leaf['unmatched_source_faces'])!=2 or len(leaf['unmatched_runtime_faces'])!=1:
        raise ValueError('Car3 source two-to-one face merge missing')
    two=leaf['unmatched_source_faces'];one=leaf['unmatched_runtime_faces'][0]
    if {face_key(f) for f in two}!={tuple([2,6,11]),tuple([2,6,13,21])} or face_key(one)!=(2,6,11,13,21):
        raise ValueError('Unexpected Car3 merged polygon geometry')
    source_area=sum(collision.face_area(base['points'],f['vertices']) for f in two)
    destination_area=collision.face_area(base['points'],one['vertices'])
    if abs(source_area-destination_area)>1e-8:raise ValueError('Car3 merged face area changed')
    for row in leaf['face_correspondence']:
        expected=row['source_color']-(row['source_color']>10)
        if row['native_color']!=expected or not row['same_polygon_flags'] or not row['same_winding']:
            raise ValueError('Car3 color/winding regression')
    return {'removed_source_normal_index':10,
        'inserted_runtime_normal_index':30,
        'inserted_runtime_normal':normals[-1],
        'retained_shifted_normals':20,
        'removed_source_color_index':10,
        'source_to_runtime_color_rule':'0..10 unchanged; 11..32 decrement by one (observed matching polygons only)',
        'source_merge_faces':[{'group':f['group'],'index':f['index'],'vertices':f['vertices'],'color':f['color']} for f in two],
        'merged_runtime_face':{'cp':one['cp'],'index':one['index'],'vertices':one['vertices'],'color':one['color']},
        'source_merged_area':source_area,'runtime_merged_area':destination_area,
        'area_difference':abs(source_area-destination_area),
        'unresolved':'Native divider ordering, branching/solid semantics, original material conversion algorithm'}

def audit():
    models={str(rel):lineage(rel) for rel in bnd.MODELS}
    if [(d['source_polygon_count'],d['runtime_polygon_count'],d['matched_geometry']) for d in models.values()]!=[(60,60,60),(60,59,58),(35,35,35)]:
        raise ValueError('Historical face inventory no longer agrees with original sources')
    car3=models[str(bnd.MODELS[1])]
    extra=car3_findings(car3)
    for rel in (bnd.MODELS[0],bnd.MODELS[2]):
        d=models[str(rel)]
        if d['matched_flags_and_material']!=d['source_polygon_count'] or d['matched_cyclic_winding']!=d['source_polygon_count']:
            raise ValueError('Previously exact BND/MDL face provenance changed')
    return {'schema':'club-bnd-mdl-lineage',
        'interpretation':'Conservative native face/leaf correspondence from saved intermediate and compiled geometry, not solid/empty semantics',
        'models':models,'car3_specific_findings':extra}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('action',choices=['compile','check']);arg=parser.parse_args()
    doc=audit()
    if arg.action=='compile':
        BASE.mkdir(parents=True,exist_ok=True);OUTPUT.write_text(json.dumps(doc,indent=2)+'\n')
    elif json.loads(OUTPUT.read_text())!=doc:raise ValueError('car2 face correspondence manifest stale')
    for k,v in doc['models'].items():
        print(k,'geometry',v['matched_geometry'],'/',v['source_polygon_count'],'to',v['runtime_polygon_count'],
              'winding',v['matched_cyclic_winding'],'CP pairs',[(x['bnd_group'],x['mdl_cp'],x['polygons']) for x in v['source_group_to_runtime_leaf']])
    print('Car3 merge area:',doc['car3_specific_findings']['source_merged_area'])
if __name__=='__main__':main()
