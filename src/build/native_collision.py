#!/usr/bin/env python3
"""polygons: experimental native .MDL CP/edge/pointer compiler, kept out of clean ROM.

Input is native geometry derived from preserved .MDL, NOT an ASC->world
converter or the missing Atari collision-compiler. Supports splitting or
adding faces using known vertices and dividers; a new edge is appended if
needed. Recalculates CP offsets, native leaves, counts and all relevant
header addresses. Existing point/normal/divider tables are immutable.
"""
import argparse
import copy
import hashlib
import json
import math
import re
from pathlib import Path

import native_model_pipeline as mdl
import native_plane_audit as plane
import native_tree as nt

ROOT=nt.ROOT
BASE=ROOT/'assets/3d/collision'
# Drone's special compact header and missing CP0 are not yet covered.
MODELS=[p for p in nt.old.MODEL_FILES if p != Path('CARS/DRONE.MDL')]
CP_MARK=re.compile(r'^\s*;\s*cpnode\s+#\d+\s+offset\s+\d+\s*$',re.I)
EDGES=re.compile(r'^\s*;\s*edges\s*$',re.I)
POINTS=re.compile(r'^\s*;\s*points\s*$',re.I)
TREE=re.compile(r'^\s*;\s*tree\s*$',re.I)


def json_path(rel): return BASE/'json'/rel.with_suffix(rel.suffix+'.collision.json')
def output_path(rel): return BASE/'generated'/rel


def source_geometry(rel):
    doc=json.loads(mdl.authoring_file(rel).read_text())
    if doc['original'] != str(rel): raise ValueError('Native geometry source identity mismatch')
    groups=doc['groups']
    template=mdl.template_file(rel).read_bytes().decode('latin1')
    original_rows=mdl.scan(template, 'MDL')
    expected={(r['group'],r['line']):r['values'] for r in original_rows}
    for group in ('vertices','normals','edges','surfaces'):
        for entry in groups[group]:
            if entry['values']!=expected.get((group,entry['line'])):
                raise ValueError('polygons cannot mix uncompiled models numeric-geometry edits with original native template')
    edges=[r['values'] for r in groups['edges']]
    verts=[r['values'] for r in groups['vertices']]
    normals=[r['values'] for r in groups['normals']]
    divs=plane.dividers_for(rel,groups)
    return edges,verts,normals,divs


def decode_face(words,edges):
    sides=words[0]&15
    if len(words)!=sides+3:raise ValueError('Malformed native polygon words')
    loop=[]; pairs=[]
    for enc in words[2:-1]:
        idx=enc&0x7fff
        if idx>=len(edges):raise ValueError('Native polygon references missing edge')
        a,b=edges[idx]
        if enc&0x8000:a,b=b,a
        loop.append(a);pairs.append((a,b))
    if not all(pairs[i][1]==pairs[(i+1)%len(pairs)][0] for i in range(sides)):
        raise ValueError('Native polygon directed edges are not continuous')
    return {'vertices':loop,'flags':words[0]&0xfff0,'divider':words[1], 'color':words[-1]}


def original_cp(rel):
    layout=nt.native_layout(rel)
    edges,_,_,_=source_geometry(rel)
    cp=[]
    for record in layout['cp_records']:
        w=record['words'];polys=[];i=0
        while i<len(w)-1:
            n=(w[i]&15)+3
            polys.append(decode_face(w[i:i+n],edges));i+=n
        if i!=len(w)-1 or w[-1]!=0:raise ValueError('Bad original CP terminator')
        cp.append({'cp_index':record['index'],'polygons':polys})
    return cp


def export_doc(rel):
    if rel not in MODELS:raise ValueError('Native polygons only supports full-header .MDL files')
    raw=nt.old.original(rel)
    return {'schema':'club-native-collision', 'source_model':str(rel),
            'source_template_sha256':hashlib.sha256(raw).hexdigest(),
            'provenance':'2026 reconstructed native .MDL tables and directed edge bits; NOT Atari mkbnd',
            'limitations':'Original point/normal/divider tables and CP memberships only; no Jaguar runtime replacement',
            'cp_lists':original_cp(rel)}


def base(v):return [float(x) for x in v]
def sub(a,b):return [a[i]-b[i] for i in range(3)]
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def dot(a,b):return sum(a[i]*b[i] for i in range(3))
def norm(a):return math.sqrt(dot(a,a))

def face_area(verts,indices):
    poly=[base(verts[i-1]) for i in indices]
    origin=poly[0]
    # 3D area from a triangle fan; supports nonplanar source quantization.
    return sum(norm(cross(sub(poly[i],origin),sub(poly[i+1],origin)))/2
               for i in range(1,len(poly)-1))


def validate_polygon(face,verts,normals,divs,original=None):
    if not isinstance(face,dict):raise ValueError('Polygon must be object')
    indices=face.get('vertices')
    if not isinstance(indices,list) or not 3<=len(indices)<=15:
        raise ValueError('Polygon vertex count must be 3..15')
    if any(type(i)!=int or i<1 or i>len(verts) for i in indices) or len(set(indices))!=len(indices):
        raise ValueError('Polygon vertex ID out of bounds or repeated')
    for k in ('flags','divider','color'):
        if type(face.get(k))!=int: raise ValueError(f'Invalid polygon {k}')
    if face['flags'] not in (0x2000,0x2040,0xa000):
        raise ValueError('Unknown native polygon flags')
    if not 0<=face['divider']<len(divs):raise ValueError('Polygon divider out of bounds')
    if not 0<=face['color']<=65535:raise ValueError('Polygon color word out of range')
    pidx,nidx=divs[face['divider']]
    if not 0<=pidx<len(verts) or not 0<=nidx<len(normals):raise ValueError('Invalid divider point/normal')
    point=verts[pidx];normal=normals[nidx];size=norm(normal)
    if size==0:raise ValueError('Zero divider normal')
    error=max(abs(dot(normal,sub(verts[i-1],point)))/size for i in indices)
    if error>plane.TOLERANCE:raise ValueError(f'Polygon plane tolerance exceeded: {error:.5f}')
    area=face_area(verts,indices)
    if area<=1e-6:raise ValueError('Degenerate zero-area polygon')
    # All vertices must be convex in the normal's projection. Existing
    # unedited faces are historically accepted; only changed/new ones use
    # this safety gate, since older concave or heavily quantized data exists.
    if original is None or face != original:
        signs=[]
        for i in range(len(indices)):
            a,b,c=[verts[indices[(i+j)%len(indices)]-1] for j in range(3)]
            d=dot(cross(sub(b,a),sub(c,b)),normal)
            if abs(d)>1e-6:signs.append(1 if d>0 else -1)
        if not signs or min(signs)!=max(signs):raise ValueError('Edited polygon is non-convex')
        if signs[0]<0:raise ValueError('Edited polygon winding opposes original native divider normal')
    return area


def validate_doc(rel,doc,topology=None):
    if rel not in MODELS:raise ValueError('Unsupported native collision model')
    original=export_doc(rel)
    if any(doc.get(k)!=original[k] for k in ('schema','source_model','source_template_sha256')):
        raise ValueError('Native collision template identity mismatch')
    cp=doc.get('cp_lists');old=original['cp_lists']
    if not isinstance(cp,list) or len(cp)!=len(old):raise ValueError('CP list count cannot change')
    edges,verts,norms,divs=source_geometry(rel)
    faces=0;new=0
    for record,base in zip(cp,old):
        if type(record)!=dict or record.get('cp_index')!=base['cp_index']:
            raise ValueError('CP index/order must remain stable')
        polygons=record.get('polygons')
        if not isinstance(polygons,list):raise ValueError('CP polygons must be a list')
        if record['cp_index']==0 and polygons:raise ValueError('Background CP0 must remain empty')
        if record['cp_index']!=0 and not polygons:raise ValueError('Cannot leave a native BSP leaf empty')
        for i,face in enumerate(polygons):
            orig=face if face in base['polygons'] else None
            validate_polygon(face,verts,norms,divs,orig)
            faces+=1
            new+=int(face != orig)
    t=topology or nt.export_doc(rel)
    nt.validate_doc(rel,t)
    # Topology leaves are described using their original CP list offsets.
    # This compiler rebinds them to new offsets via their original CP indices.
    return {'model':str(rel),'polygons':faces,'changed_or_added_polygon_positions':new,
            'existing_edges':len(edges),'original_polygons':sum(len(r['polygons']) for r in old),
            'original_nodes':len(nt.native_layout(rel)['nodes'])}


def compile_text(rel,doc,topology=None):
    topo=topology or nt.export_doc(rel)
    stats=validate_doc(rel,doc,topo)
    old_doc=export_doc(rel)
    original=nt.old.original(rel)
    if doc['cp_lists']==old_doc['cp_lists'] and nt.compiled_records(topo)==nt.original_records(nt.native_layout(rel)):
        stats.update(added_edges=0,cp_delta_bytes=0,tree_delta_bytes=0,compiled_nodes=stats['original_nodes'])
        return original,stats
    layout=nt.native_layout(rel)
    edges,verts,norms,divs=source_geometry(rel)
    old_edge_count=len(edges)
    lookup={tuple(sorted(pair)):i for i,pair in enumerate(edges)}
    cp_lines=[]; new_offsets={};bytes_in_cp=0
    for record in doc['cp_lists']:
        new_offsets[record['cp_index']]=bytes_in_cp
        cp_lines.append(f"; cpnode #{record['cp_index']}  offset {bytes_in_cp}\n")
        for face in record['polygons']:
            vertices=face['vertices'];refs=[]
            for i,a in enumerate(vertices):
                b=vertices[(i+1)%len(vertices)]
                if a==b:raise ValueError('Zero-length edge')
                key=tuple(sorted((a,b)))
                if key not in lookup:
                    if len(edges)>=0x8000:raise ValueError('Native edge index overflow')
                    lookup[key]=len(edges);edges.append([a,b])
                idx=lookup[key]
                refs.append(idx | (0 if edges[idx]==[a,b] else 0x8000))
            words=[face['flags']|len(vertices),face['divider'],*refs,face['color']]
            cp_lines.append('\tdc.w\t'+', '.join(f'${x:04x}' for x in words)+'\n')
            bytes_in_cp+=2*len(words)
        cp_lines.append('\tdc.w\t0\n');bytes_in_cp+=2
    extra_edges=edges[old_edge_count:]
    old_cp_records=layout['cp_records']
    old_by_offset={r['offset']:r['index'] for r in old_cp_records}
    tree_records=nt.compiled_records(topo)
    node_lines=[]
    for i,record in enumerate(tree_records):
        node_lines.append(f'\t\t\t; Node {8*i}\n')
        if record[0]=='split':
            node_lines.append(f'\tdc.w\t0, {record[1]}, {record[2]}, {record[3]}\n')
        else:
            old_cp_index=old_by_offset[record[2]]
            node_lines.append('\tdc.w\t1, 0\n')
            node_lines.append(f'\tdc.l\t{new_offsets[old_cp_index]}\n')
    header=layout['header_pointers'];p={name:v['number'] for name,v in header.items()}
    new_tris=p['tris']+4*len(extra_edges)
    new_tree=(new_tris+bytes_in_cp+3)&~3
    old_tree=p['tree']
    new_ptrs={'points':p['points']+4*len(extra_edges),'tris':new_tris,
              'end of tris':new_tris+bytes_in_cp-(p['tris']+layout['cp_bytes']-p['end of tris']),
              'tree':new_tree,'calculated colors':new_tree+8*len(tree_records)}
    lines=layout['lines']
    first_cp=next(i for i,line in enumerate(lines) if CP_MARK.match(line))
    tree_header=next(i for i in range(first_cp,len(lines)) if TREE.match(lines[i]))
    e_marker=next(i for i,line in enumerate(lines) if EDGES.match(line))
    p_marker=next(i for i in range(e_marker+1,len(lines)) if POINTS.match(lines[i]))
    if not (e_marker<p_marker<first_cp<tree_header<layout['first_node']<layout['after_nodes']):
        raise ValueError('Unexpected native model section ordering')
    patch={}
    if extra_edges:
        count_idx=next((i for i,line in enumerate(lines) if nt.HEADER_COUNT.match(line) and nt.HEADER_COUNT.match(line)[2].upper()=='NUM_EDGES'),None)
        if count_idx is None:raise ValueError('Native model has no edge count')
        match=re.match(r'^(\s*dc\.w\s+)\d+(\s*;\s*NUM_EDGES\s*)(\r?\n?)$',lines[count_idx],re.I)
        if match is None:raise ValueError('Unrecognized native NUM_EDGES header')
        patch[count_idx]=match[1]+str(old_edge_count+len(extra_edges))+match[2]+match[3]
    for key,new in new_ptrs.items():
        item=header[key];i=item['line'];match=nt.HEADER_PTR.match(lines[i])
        if match is None:raise ValueError('Malformed relocation header')
        if new!=item['number']:
            patch[i]=match[1]+match[2]+'+'+str(new)+match[4]+match[6]
    edge_lines=[f'\tdc.w\t${a:04x}, ${b:04x}\t; polygons edge #{old_edge_count+i}\n' for i,(a,b) in enumerate(extra_edges)]
    result=[]
    for i,line in enumerate(lines):
        if i==p_marker:result.extend(edge_lines)
        if i==first_cp:result.extend(cp_lines)
        if i==layout['first_node']:result.extend(node_lines)
        if first_cp<=i<tree_header or layout['first_node']<=i<layout['after_nodes']:
            continue
        result.append(patch.get(i,line))
    raw=''.join(result).encode('latin1')
    checked=nt.native_layout(rel,raw)
    if checked['polygons']!=stats['polygons'] or checked['cp_bytes']!=bytes_in_cp:
        raise ValueError('Generated CP data fails independent native parser')
    if checked['header_counts']['NUM_EDGES']!=len(edges):raise ValueError('Compiled edge count mismatch')
    reconstructed=[]
    for record in checked['cp_records']:
        polys=[];words=record['words'];at=0
        while at<len(words)-1:
            k=(words[at]&15)+3
            polys.append(decode_face(words[at:at+k],edges))
            at+=k
        reconstructed.append({'cp_index':record['index'],'polygons':polys})
    if reconstructed!=doc['cp_lists']:
        raise ValueError('Native re-decode differs from requested authored polygon loops')
    parsed_cp={r['index']:r['offset'] for r in checked['cp_records']}
    if parsed_cp!=new_offsets:raise ValueError('Compiled CP offsets mismatch')
    if checked['header_pointers']['tree']['number']!=new_tree:
        raise ValueError('Compiled tree alignment mismatch')
    if checked['header_pointers']['calculated colors']['number']!=new_ptrs['calculated colors']:
        raise ValueError('Compiled color relocation mismatch')
    for n in checked['nodes']:
        if n['type']=='leaf' and n['cp_offset'] not in set(new_offsets.values()):
            raise ValueError('Compiled tree has dangling CP reference')
    stats.update(added_edges=len(extra_edges),cp_delta_bytes=bytes_in_cp-layout['cp_bytes'],
                 tree_delta_bytes=new_tree-old_tree,compiled_nodes=len(tree_records),
                 new_tree_offset=new_tree,new_cp_offsets=new_offsets)
    return raw,stats


def split_quad_probe():
    """Split first Car 2 quad along the 0->2 diagonal, preserving its plane."""
    rel=Path('CAR2.MDL');doc=export_doc(rel)
    orig=doc['cp_lists'][1]['polygons'][0]
    if len(orig['vertices'])!=4:raise ValueError('Car 2 reference quad changed')
    v=orig['vertices'];first=copy.deepcopy(orig);second=copy.deepcopy(orig)
    first['vertices']=[v[0],v[1],v[2]]
    second['vertices']=[v[0],v[2],v[3]]
    doc['cp_lists'][1]['polygons'][0:1]=[first,second]
    edges,verts,_,_=source_geometry(rel)
    if abs(face_area(verts,v)-face_area(verts,first['vertices'])-face_area(verts,second['vertices']))>1e-8:
        raise ValueError('Car 2 surface area not conserved')
    raw,stats=compile_text(rel,doc)
    dest=BASE/'probes'/'CAR2_split_quad.MDL'
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_bytes(raw)
    (dest.parent/'CAR2_split_quad.collision.json').write_text(json.dumps(doc,indent=2)+'\n')
    stats['area_conservation_error']=abs(face_area(verts,v)-face_area(verts,first['vertices'])-face_area(verts,second['vertices']))
    return stats


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('action',choices=['export','compile','check','probe','audit'])
    ap.add_argument('--only',action='append')
    args=ap.parse_args()
    if args.action=='probe':
        print(json.dumps(split_quad_probe(),indent=2));return
    rels=[Path(x) for x in args.only] if args.only else MODELS
    results={}
    for rel in rels:
        if rel not in MODELS:raise ValueError('Unsupported source model')
        dest=json_path(rel)
        if args.action=='export':
            if dest.exists():raise ValueError('Refusing to overwrite authored source')
            dest.parent.mkdir(parents=True,exist_ok=True)
            dest.write_text(json.dumps(export_doc(rel),indent=2)+'\n')
            result={'exported':True}
        else:
            doc=json.loads(dest.read_text())
            # Editing native_tree native-tree JSON and the polygons CP JSON can be combined.
            topo=json.loads(nt.path(rel).read_text())
            raw,result=compile_text(rel,doc,topo)
            outfile=output_path(rel)
            if args.action=='check':
                if not outfile.exists() or outfile.read_bytes()!=raw:raise ValueError(f'{rel}: stale native .MDL')
            elif args.action=='compile':
                outfile.parent.mkdir(parents=True,exist_ok=True);outfile.write_bytes(raw)
        print(args.action.upper(),rel,result)
        results[str(rel)]=result
    if args.action in ('compile','audit') and not args.only:
        (BASE/'collision_index.json').write_text(json.dumps(results,indent=2)+'\n')
    print('TOTAL',args.action,len(rels))

if __name__=='__main__':main()
