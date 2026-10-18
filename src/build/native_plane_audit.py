#!/usr/bin/env python3
"""2026 source-backed plane analysis of the surviving .BND/.MDL polygon tables.

Native divider = (zero-based point index, zero-based normal index).
A polygon's second word references the divider. This is supported by
BNDHEAD.INC, mktp.c and crash.gas, not inferred from bsp_geometry's axis BSPs.
The audit checks every polygon's edge-derived vertex loop against the
corresponding native plane. This is a diagnostic, not a normal generator.
"""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path

import native_model_pipeline as mdl
import native_tree as nt

OUT=nt.BASE/'native_plane_audit.json'
TOLERANCE=2.0  # Native units: allow original fixed-point quantization residuals.


def dividers_for(rel,groups):
    if rel.suffix.upper()=='.BND':
        return [r['values'] for r in groups['collision_dividers']]
    text=nt.old.original(rel).decode('latin1')
    m=re.search(r'^\w+_data:\s*$',text,re.M|re.I)
    if not m:raise ValueError(f'{rel}: missing native model data label')
    if '; edges' not in text[m.end():]:raise ValueError(f'{rel}: missing edge boundary')
    table=text[m.end():].split('; edges',1)[0]
    result=[]
    for line in table.splitlines():
        row=nt.WORDRE.match(line)
        if row:
            terms=row[2].split(',')
            if len(terms)!=2:raise ValueError(f'{rel}: wrong divider width')
            result.append([nt.old.get_int(x) for x in terms])
    return result


def audit_model(rel, doc_override=None):
    d=doc_override if doc_override is not None else json.loads(mdl.authoring_file(rel).read_text())
    groups=d['groups']
    pts=[r['values'] for r in groups['vertices']]
    norms=[r['values'] for r in groups['normals']]
    divs=dividers_for(rel,groups)
    polygons=[r['values'] for r in groups['surfaces']]
    faces,bad=mdl.faces_from_edges(groups['edges'],groups['vertices'],groups['surfaces'])
    if bad or len(faces)!=len(polygons):
        raise ValueError(f'{rel}: {len(bad)} broken polygon loops, {len(faces)} / {len(polygons)} decoded')
    planes=[]
    for i,idx in enumerate(divs):
        if len(idx)!=2 or any(type(z)!=int for z in idx):raise ValueError(f'{rel}: divider {i} width')
        pt,nr=idx
        if not (0<=pt<len(pts) and 0<=nr<len(norms)):
            raise ValueError(f'{rel}: divider {i} references invalid point/normal')
        n=norms[nr]; p=pts[pt]
        mag=math.sqrt(sum(float(x*x) for x in n))
        if mag==0:raise ValueError(f'{rel}: zero-length normal {nr}')
        unit=[v/mag for v in n]
        planes.append({'point':pt,'normal':nr,'unit_normal':unit,'offset':sum(unit[k]*p[k] for k in range(3))})
    maxres=0.0; sumres=0.0; total_vertex_uses=0; worst=None
    used=set()
    for f in faces:
        idx=f['surface_index']
        words=polygons[idx]
        if not (0<=words[1]<len(planes)):
            raise ValueError(f'{rel}: invalid polygon divider {idx}')
        i=words[1]; used.add(i)
        plane=planes[i]
        error=max(abs(sum(plane['unit_normal'][k]*pts[vid-1][k] for k in range(3))-plane['offset']) for vid in f['vertices'])
        sumres+=error;total_vertex_uses+=len(f['vertices'])
        if error>maxres:
            maxres=error;worst={'surface_index':idx,'divider_index':i,'residual_native_units':error}
    if maxres>TOLERANCE:
        raise ValueError(f'{rel}: polygon exceeds native plane tolerance {TOLERANCE}: {worst}')
    return {'source':str(rel),'document_sha256':hashlib.sha256(mdl.authoring_file(rel).read_bytes()).hexdigest(),
            'dividers':len(divs),'normals':len(norms),'vertices':len(pts),'polygon_surfaces':len(faces),
            'referenced_dividers':len(used),'max_plane_residual_native_units':round(maxres,6),
            'mean_polygon_max_residual_native_units':round(sumres/len(faces),6) if faces else 0.0,
            'worst_surface':worst}


def generate():
    return {'schema':'club-native-plane-audit',
            'provenance':'BNDHEAD.INC, mktp.c, crash.gas, native .MDL/.BND vertex/normal/divider/edge arrays',
            'meaning':'Unsigned reference indices, signed normals, plane equation n dot (p - point) = 0',
            'quantization_tolerance_native_units':TOLERANCE,
            'models':{str(rel):audit_model(rel) for rel in mdl.manifest_paths()}}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('action',choices=('compile','check'))
    a=p.parse_args()
    result=generate()
    if a.action=='check':
        if not OUT.exists() or json.loads(OUT.read_text())!=result:raise ValueError('Native plane audit stale')
    else:
        OUT.parent.mkdir(parents=True,exist_ok=True)
        OUT.write_text(json.dumps(result,indent=2)+'\n')
    for k,v in result['models'].items():
        print(a.action.upper(),k,'polygon surfaces',v['polygon_surfaces'],'max residual',v['max_plane_residual_native_units'])
    print('TOTAL',len(result['models']),'native files',sum(v['polygon_surfaces'] for v in result['models'].values()),'polygons')

if __name__=='__main__':main()
