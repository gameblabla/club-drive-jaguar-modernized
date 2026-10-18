#!/usr/bin/env python3
"""Read-only Jaguar collision-data sanity audit; 2026 reconstruction.

From original `mktp.c` lines 100-114, a surface's second word indexes
`dividers[]`, whose second word indexes the vector/normal array. Polygon
edge references are 15-bit indices; the high bit encodes edge direction.
This audit does NOT regenerate the BSP or infer its splitting algorithm.
"""
from pathlib import Path
import json, math
import native_model_pipeline as mdl
ROOT=mdl.ROOT
OUT=ROOT/'assets/3d/geometry'/'collision_audit.json'

def main():
    result={'source':'surviving mktp.c, model.doc, CARS/*.BND, CARS/*.MDL',
            'status':'checked indexes, normals and BND-to-MDL vertex flip (no BSP regeneration)',
            'models':{}}
    for name in ('CAR2','CAR3','DRONE'):
        b=json.loads(mdl.authoring_file(Path('CARS')/(name+'.BND')).read_text())['groups']
        m=json.loads(mdl.authoring_file(Path('CARS')/(name+'.MDL')).read_text())['groups']
        points=[r['values'] for r in b['vertices']];norms=[r['values'] for r in b['normals']]
        divs=[r['values'] for r in b['collision_dividers']]
        edges=[r['values'] for r in b['edges']]
        surfaces=[r['values'] for r in b['surfaces']]
        mpoints=[r['values'] for r in m['vertices']]
        assert len(points)==len(mpoints) and all([-v[0],v[1],-v[2]]==p for v,p in zip(points,mpoints)),f'{name}: bnd2mdl -flip rule no longer holds'
        assert all(0<=p<len(points) and 0<=n<len(norms) for p,n in divs),f'{name}: bad divider point/normal index'
        assert all(1<=i<=len(points) for edge in edges for i in edge),f'{name}: invalid 1-based edge point'
        assert all(0<=s[1]<len(divs) and len(s)==(s[0]&15)+3 and all(0<=e&0x7fff<len(edges) for e in s[2:-1]) for s in surfaces),f'{name}: invalid polygon divider/edge'
        faces,unresolved=mdl.faces_from_edges(b['edges'],b['vertices'],b['surfaces'])
        assert not unresolved,f'{name}: {len(unresolved)} broken polygon loops'
        max_plane_residual=0
        for f in faces:
            s=surfaces[f['surface_index']]
            n=norms[divs[s[1]][1]]
            length=math.sqrt(sum(t*t for t in n))
            verts=[points[j-1] for j in f['vertices']]
            for v in verts[1:]:
                a=verts[0]
                resid=abs(sum(n[c]*(v[c]-a[c]) for c in range(3)))/max(1,length)
                max_plane_residual=max(max_plane_residual,resid)
        result['models'][name]={'vertices':len(points),'edges':len(edges),'normals':len(norms),
                               'dividers':len(divs),'polygon_surfaces':len(surfaces),
                               'closed_polygon_loops':len(faces),
                               'max_surface_plane_residual_units':round(max_plane_residual,4),
                               'all_divider_references_valid':True,'mdl_flip_exact':True}
    OUT.write_text(json.dumps(result,indent=2)+'\n')
    for name,data in result['models'].items():print('COLLISION CHECK',name, data)
if __name__=='__main__':main()
