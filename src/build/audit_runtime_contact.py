#!/usr/bin/env python3
"""CONTACT_AUDIT recovered runtime collision-source audit and conservative geometry preview.

This is a 2026 static source-backed analysis of candidate collision surfaces,
NOT a Jaguar GPU emulator, fixed-point implementation, or runtime collision ROM.
The preserved native MDL and the isolated car2/car3 Car2/Car3 fan probes are inputs.
"""
from asset_paths import asset_file
import argparse
import hashlib
import json
import math
from collections import Counter
from pathlib import Path

import native_geometry as native

ROOT = native.ROOT
BASE = ROOT/'assets/diagnostics/contact_analysis'
REPORT = BASE/'runtime_contact_audit.json'
SOURCES = {
    'precomp.gas': ['moveq\t#$9,temp2', 'collision detection (bit 3)'],
    '3dend.gas': ['drvloop:', 'include "close.gas"', 'include "drive.gas"'],
    'mktp.gas': ['btst\t#0,temp', 'movei\t#tPOLYS,temp2', 'storew\tavgX,(temp2)', 'storew\tavgY,(temp2)', 'storew\tavgZ,(temp2)', 'storew\tmaxDistance,(temp2)'],
    'close.gas': ['btst\t#0,temp', 'btst\t#6,polyflags', 'movei\t#SURF_LIST, temp', 'movei\t#tPOLYS, tPolys', 'movei\t#tCLOSE_LIST, closeList', 'include "crash.gas"', 'movei\t#SURFS_END,surfsend'],
    'crash.gas': ['loadw\t(poly1),temp', 'moveta\ttemp,poly_flags', 'loadw\t(poly1),temp', 'movei\t#crashedge,edgeloop', 'movei\t#crashlp,innerLoop', 'CAR_FORCE and CAR_TORQUE'],
    'drive.gas': ['CAR_FORCE', 'CAR_TORQUE'],
    'tree.gas': ['drawCP', 'cpFront', 'cpBack'],
}

def source_evidence():
    result = {}
    for name, terms in SOURCES.items():
        data = asset_file(name).read_bytes()
        txt = data.decode('latin1')
        for term in terms:
            if term not in txt:
                raise ValueError(f'Runtime collision source evidence absent: {name}: {term!r}')
        result[name] = {'sha256': hashlib.sha256(data).hexdigest(), 'verified_fragments': terms}
    # Do not mistake a GPU draw-order traversal for a solid/empty collision traversal.
    return result

def candidate(flags, band_flags=0):
    """Only source-verified *flag gates*, not radius, side, or edge tests."""
    if type(flags) is not int or flags & ~0xfff0 or flags < 0:
        raise ValueError('Invalid native polygon flag word')
    if type(band_flags) is not int or not 0<=band_flags<=0xffff:
        raise ValueError('Invalid band flag word')
    return not (flags & 0x40 or band_flags & 0x1)

def face_records(doc):
    for cp in doc['cp_lists']:
        for ix, face in enumerate(cp['polygons']):
            yield (cp['cp_index'],ix,face)

def model_summary(rel):
    d = native.export_doc(rel)
    flags = Counter(f['flags'] for _,_,f in face_records(d))
    return {'model':str(rel),'faces':sum(flags.values()),'cp_lists':len(d['cp_lists']),
        'eligible_when_band_enabled':sum(n for k,n in flags.items() if candidate(k)),
        'skipped_by_polygon_flag6':sum(n for k,n in flags.items() if not candidate(k)),
        'flag_words':{'0x%04x'%k:v for k,v in sorted(flags.items())},
        'model_sha256':hashlib.sha256(asset_file(rel).read_bytes()).hexdigest()}

def vsub(a,b):return [a[i]-b[i] for i in range(3)]
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def dot(a,b):return sum(a[i]*b[i] for i in range(3))
def face_point_loop(doc,face):return [doc['points'][x-1] for x in face['vertices']]
def projected(points, drop):return [(p[(drop+1)%3],p[(drop+2)%3]) for p in points]

def winding_inside(point, polygon, tolerance=1e-8):
    """Projected convex polygon footprint; strict edge sign, boundaries included."""
    signs=[]
    for i,(ax,ay) in enumerate(polygon):
        bx,by=polygon[(i+1)%len(polygon)]
        value=(bx-ax)*(point[1]-ay)-(by-ay)*(point[0]-ax)
        if abs(value)>tolerance:signs.append(value>0)
    return not signs or all(s == signs[0] for s in signs)

def fan_preview(original,edited,cp,index):
    old_group=original['cp_lists'][cp]
    new_group=edited['cp_lists'][cp]
    if old_group['cp_index']!=cp or new_group['cp_index']!=cp:
        raise ValueError('CP ownership mismatch')
    a=old_group['polygons']; b=new_group['polygons']
    if len(b)!=len(a)+3 or b[:index]!=a[:index] or b[index+4:]!=a[index+1:]:
        raise ValueError('Expected one unchanged-CP quad-to-four-triangle replacement')
    quad=a[index];fan=b[index:index+4]
    if len(quad['vertices'])!=4 or any(len(f['vertices'])!=3 for f in fan):
        raise ValueError('Expected one quad and exactly four triangles')
    oldpoints=face_point_loop(original,quad)
    surface_normal=cross(vsub(oldpoints[1],oldpoints[0]),vsub(oldpoints[2],oldpoints[0]))
    length=math.sqrt(dot(surface_normal,surface_normal))
    if length <= 0:raise ValueError('Degenerate original surface')
    drop=max(range(3),key=lambda i:abs(surface_normal[i]))
    outline=projected(oldpoints,drop)
    triangles=[projected(face_point_loop(edited,f),drop) for f in fan]
    if any((f['flags'],f['color'])!=(quad['flags'],quad['color']) for f in fan):
        raise ValueError('Fan changed original collision flags/material')
    if any(f['divider'] != fan[0]['divider'] for f in fan):
        raise ValueError('Fan requires one common new plane divider')
    if not candidate(quad['flags']) or not all(candidate(f['flags']) for f in fan):
        raise ValueError('Probe surface is not collision-eligible')
    # Native points can have quantization error, so use the projected footprint.
    all2d=[p for polygon in [outline] for p in polygon]
    xmin=min(p[0] for p in all2d);xmax=max(p[0] for p in all2d)
    ymin=min(p[1] for p in all2d);ymax=max(p[1] for p in all2d)
    if xmax==xmin or ymax==ymin:raise ValueError('Degenerate projection')
    # Include a margin so outside contacts are checked as well as inside ones.
    dx=xmax-xmin;dy=ymax-ymin
    disagreements=[];inside=outside=0
    # 31^2 grid. Tests a segment perpendicular to the old face plane would hit
    # the footprint iff its center falls inside (assuming no other faces).
    for iy in range(31):
        for ix in range(31):
            point=(xmin-dx/5+(ix+.317)*dx*1.4/31,
                   ymin-dy/5+(iy+.613)*dy*1.4/31)
            before=winding_inside(point,outline)
            after=any(winding_inside(point,t) for t in triangles)
            if before:inside+=1
            else:outside+=1
            if before!=after:disagreements.append({'grid':[ix,iy],'point':point})
    if disagreements:raise ValueError(f'Collision footprint changed at {len(disagreements)} probe samples')
    # The source compiler already validated the plane/winding/area; this audit
    # additionally checks the runtime *gate* and footprint classification.
    return {'cp':cp,'original_face':index,'original_flags':quad['flags'],
            'fan_flags':[f['flags'] for f in fan],'collision_gate_preserved':True,
            'sample_count':inside+outside,'inside_samples':inside,'outside_samples':outside,
            'footprint_disagreements':0,'render_bsp_tree_used_for_contact':False,
            'limitations':'Projected convex footprint, not fixed-point Jaguar control-line/force emulation'}

def segment_crosses_face(doc,face,start,end,band_flags=0):
    """Floating-point line/convex-face preview, NOT Jaguar fixed-point collision."""
    if not candidate(face['flags'],band_flags):return False
    points=face_point_loop(doc,face)
    n=cross(vsub(points[1],points[0]),vsub(points[2],points[0]))
    if dot(n,n)<=1e-16:raise ValueError('Degenerate contact-test face')
    a=dot(n,vsub(start,points[0]));b=dot(n,vsub(end,points[0]))
    if a*b>0 or abs(a-b)<=1e-8:return False
    t=a/(a-b)
    if t<0 or t>1:return False
    hit=[start[j]+(end[j]-start[j])*t for j in range(3)]
    drop=max(range(3),key=lambda i:abs(n[i]))
    return winding_inside(projected([hit],drop)[0],projected(points,drop))

def contact_fixtures(original,edited,cp,index):
    old=original['cp_lists'][cp]['polygons'][index]
    replacement=edited['cp_lists'][cp]['polygons'][index:index+4]
    polygon=face_point_loop(original,old)
    n=cross(vsub(polygon[1],polygon[0]),vsub(polygon[2],polygon[0]))
    mag=math.sqrt(dot(n,n))
    unit=[v/mag for v in n]
    center=[sum(p[j] for p in polygon)/len(polygon) for j in range(3)]
    def shifted(point,d):return [point[j]+d*unit[j] for j in range(3)]
    # Shift parallel to a polygon edge by a multiple of its span for outside hit.
    delta=vsub(polygon[1],polygon[0])
    outside=[center[j]+3*delta[j] for j in range(3)]
    cases={
        'through_center': (shifted(center,-100),shifted(center,100),0),
        'outside_edge': (shifted(outside,-100),shifted(outside,100),0),
        'same_side': (shifted(center,25),shifted(center,75),0),
        'band_nocollide': (shifted(center,-100),shifted(center,100),1),
    }
    results={}
    for label,(start,end,band) in cases.items():
        before=segment_crosses_face(original,old,start,end,band)
        after=any(segment_crosses_face(edited,f,start,end,band) for f in replacement)
        if before!=after:raise ValueError(f'Contact line preview changed for {label}')
        results[label]={'original':before,'edited':after}
    if (results['through_center']['original'],results['outside_edge']['original'],
        results['same_side']['original'],results['band_nocollide']['original']) != (True,False,False,False):
        raise ValueError('Unexpected baseline floating-point contact fixture behavior')
    return results

def probe_pair(which):
    if which=='CAR2':
        rel=Path('CARS/CAR2.MDL'); data=ROOT/'assets/3d/conversion/car2/probes'
        edited=json.loads((data/'CAR2_runtime.geometry.json').read_text())
        info=json.loads((data/'bridge_probe.json').read_text())
        cp=info['source_group'];index=info['native_face_index']
    elif which=='CAR3':
        rel=Path('CARS/CAR3.MDL');data=ROOT/'assets/3d/conversion/car3/probes'
        edited=json.loads((data/'CAR3_runtime.geometry.json').read_text())
        info=json.loads((data/'probe.json').read_text())
        cp=info['runtime_cp'];index=info['runtime_index']
    else:raise ValueError('Unknown native collision experiment')
    original=native.export_doc(rel)
    out=fan_preview(original,edited,cp,index)
    out['contact_line_fixtures']=contact_fixtures(original,edited,cp,index)
    out.update(model=str(rel),experiment=which,
        edited_data_sha256=hashlib.sha256((data/('CAR2_runtime.geometry.json' if which=='CAR2' else 'CAR3_runtime.geometry.json')).read_bytes()).hexdigest())
    return out

def inspect():
    originals=[model_summary(r) for r in native.MODELS]
    probes=[probe_pair('CAR2'),probe_pair('CAR3')]
    return {'schema':'club-runtime-contact-audit',
        'purpose':'Source-grounded candidate-surface flags and geometry footprint preview',
        'evidence':source_evidence(),
        'runtime_path':['precomp.gas','mktp.gas','3dend.gas','close.gas','crash.gas','drive.gas'],
        'known_gates':{'band_nocollide_bit':0,'polygon_ignore_collide_bit':6,
            'polygon_candidates_scanned_from':'SURF_LIST',
            'polygon_centers_and_radius':'tPOLYS computed in mktp.gas',
            'contact_includes':'band distance, divider close list, polygon radius, plane crossing and oriented edges',
            'render_tree_only':'tree.gas drawing order, not a solid/empty collision test'},
        'original_native_models':originals,'isolated_geometry_probes':probes,
        'clean_rom_modified':False,
        'limitations':['No emulator collision/contact execution was performed',
          'A footprint match does not establish identical force, torque or timing',
          'No world environment collision ownership or patched cartridge is claimed']}

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('action',choices=['compile','check','show'])
    args=ap.parse_args()
    data=inspect()
    if args.action=='compile':
        BASE.mkdir(exist_ok=True,parents=True)
        REPORT.write_text(json.dumps(data,indent=2)+'\n')
    elif args.action=='check':
        if json.loads(REPORT.read_text())!=data:
            raise ValueError('contact_audit runtime contact audit manifest is stale')
    print('Runtime contact evidence:',len(data['evidence']),'assembly files')
    print('Native models:',len(data['original_native_models']))
    for probe in data['isolated_geometry_probes']:
        print(probe['experiment'],probe['sample_count'],'projected contact footprints, disagreements',probe['footprint_disagreements'])
    if args.action=='show':print(json.dumps(data,indent=2))

if __name__=='__main__':main()
