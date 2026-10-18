#!/usr/bin/env python3
"""Conservative provenance comparison of Atari BND intermediates and MDL output.
Matches source polygons by sorted vertex IDs; never assumes CP-group/material parity.
"""
from asset_paths import asset_file
from collections import Counter
import argparse, json
from pathlib import Path
import native_bnd as bnd
import native_model_pipeline as mdl
import native_collision as cp
import native_tree as tree
OUTPUT=bnd.BASE/'bnd_mdl_audit.json'

def audit(rel):
    data=bnd.decode(bnd.original(rel))
    compiled=mdl.scan((asset_file(rel.with_suffix('.MDL'))).read_text(),'MDL')
    arr=lambda kind:[r['values'] for r in compiled if r['group']==kind]
    mdlpts=arr('vertices');mdlnorm=arr('normals');mdledges=arr('edges')
    mdlfaces=[cp.decode_face(w,mdledges) for w in arr('surfaces')]
    bndfaces=[f for group in data['cp_lists'] for f in group['polygons']]
    runtime=tree.native_layout(rel.with_suffix('.MDL'))
    canon=lambda f:tuple(sorted(f['vertices']))
    typed=lambda f:(canon(f),f['flags'],f['color'])
    common_geometry=Counter(map(canon,bndfaces))&Counter(map(canon,mdlfaces))
    common_material=Counter(map(typed,bndfaces))&Counter(map(typed,mdlfaces))
    unmatched_bnd=Counter(map(canon,bndfaces))-common_geometry
    unmatched_mdl=Counter(map(canon,mdlfaces))-common_geometry
    n=len(data['normals']);normals_matching=sum(1 for p,q in zip(data['normals'],mdlnorm) if [-p[0],p[1],-p[2]]==q)
    return {'source_bnd':str(rel),'matched_mdl':str(rel.with_suffix('.MDL')),
        'coordinate_rule':'MDL=(-BND.x, BND.y, -BND.z)',
        'coordinate_match':all([-p[0],p[1],-p[2]]==q for p,q in zip(data['points'],mdlpts)) and len(data['points'])==len(mdlpts),
        'points':len(mdlpts),'normal_transform_matches':normals_matching,'normals_total':n,
        'exact_edges_at_same_index':sum(p==q for p,q in zip(data['edges'],mdledges)),
        'bnd_edges':len(data['edges']),'mdl_edges':len(mdledges),
        'bnd_polygons':len(bndfaces),'mdl_polygons':len(mdlfaces),
        'geometry_matched_polygons':sum(common_geometry.values()),
        'geometry_and_flags_color_matched_polygons':sum(common_material.values()),
        'unmatched_BND_vertex_sets':[list(k) for k in unmatched_bnd.elements()],
        'unmatched_MDL_vertex_sets':[list(k) for k in unmatched_mdl.elements()],
        'mdl_CP_record_count':len(runtime['cp_records']),'mdl_header_CP_count':runtime['header_counts'].get('NUM_CPS'),
        'mdl_tree_nodes':len(runtime['nodes']),
        'bnd_group_polygon_counts':[len(x['polygons']) for x in data['cp_lists']],
        'bnd_sizeCPsTable':data['sizes']['cps'],
        'warning':'Sets ignore winding; material/CP ownership must be independently recovered before runtime use'}

def main():
    x={str(rel):audit(rel) for rel in bnd.MODELS}
    if not all(t['coordinate_match'] for t in x.values()):raise ValueError('Recovered coordinate convention changed')
    OUTPUT.write_text(json.dumps(x,indent=2)+'\n')
    for name,v in x.items():
        print(name,'points',v['points'],'geometry',v['geometry_matched_polygons'],'/',v['bnd_polygons'],v['mdl_polygons'],
              'material',v['geometry_and_flags_color_matched_polygons'],'normals',v['normal_transform_matches'],'/',v['normals_total'])
if __name__=='__main__':main()
