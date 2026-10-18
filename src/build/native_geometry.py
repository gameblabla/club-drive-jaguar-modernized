#!/usr/bin/env python3
"""geometry: isolated Jaguar-native full-table collision authoring experiment.

Reconstructs vertex/normal/divider/edge/CP/tree tables from an editable JSON
for eight original, full-header car .MDL models. Retains original edge numbers,
CP membership and original runtime model files. New faces may use new points,
normals and dividers; all original geometry may be numerically edited subject
to conservative plane/winding validation. NOT Atari's missing environment
compiler and NOT a physics/gameplay validation or in-game modification.
"""
import argparse
import copy
import hashlib
import json
import math
import re
from pathlib import Path

import native_collision as polygons
import native_model_pipeline as model
import native_tree as tree

ROOT=tree.ROOT
BASE=ROOT/'assets/3d/tables'
MODELS=polygons.MODELS
HEADER_COUNT=tree.HEADER_COUNT
HEADER_PTR=tree.HEADER_PTR

def json_path(rel):return BASE/'json'/rel.with_suffix(rel.suffix+'.geometry.json')
def output_path(rel):return BASE/'generated'/rel

def export_doc(rel):
    if rel not in MODELS: raise ValueError('Unsupported native full-header car model')
    edges,points,normals,dividers=polygons.source_geometry(rel)
    return {'schema':'club-native-geometry','source_model':str(rel),
        'source_template_sha256':hashlib.sha256(tree.old.original(rel)).hexdigest(),
        'provenance':'Derived from preserved Jaguar MDL tables, not Atari original model compiler',
        'safety':'Isolated authoring only; never patches original runtime includes',
        'points':copy.deepcopy(points),'normals':copy.deepcopy(normals),
        'dividers':copy.deepcopy(dividers),'cp_lists':polygons.original_cp(rel)}

def validate_geometry(rel,doc,topology=None):
    orig=export_doc(rel)
    if any(doc.get(k)!=orig[k] for k in ('schema','source_model','source_template_sha256')):
        raise ValueError('Native geometry identity or source hash mismatch')
    points=doc.get('points');normals=doc.get('normals');dividers=doc.get('dividers')
    for key,records,arity,minlen,maxlen in (
        ('points',points,3,len(orig['points']),65535),
        ('normals',normals,3,len(orig['normals']),65535),
        ('dividers',dividers,2,len(orig['dividers']),65535)):
        if not isinstance(records,list) or not minlen<=len(records)<=maxlen:
            raise ValueError(f'{key}: cannot delete original entries or overflow count')
        if any(not isinstance(row,list) or len(row)!=arity or
                any(type(x)!=int for x in row) for row in records):
            raise ValueError(f'{key}: expected integral native word rows')
        if any(any(x < -32768 or x > 32767 for x in row) for row in records):
            raise ValueError(f'{key}: signed 16-bit overflow')
    for n in normals:
        length=polygons.norm(n)
        if not 32700<=length<=32820:
            raise ValueError('Normal must be 1.15 fixed-point unit length')
    for p,n in dividers:
        if not 0<=p<len(points) or not 0<=n<len(normals):
            raise ValueError('Divider point/normal index out of bounds')
    old=orig['cp_lists'];cp=doc.get('cp_lists')
    if not isinstance(cp,list) or len(cp)!=len(old):
        raise ValueError('CP list count cannot change')
    origpoints=orig['points'];orignormals=orig['normals'];origdiv=orig['dividers']
    changed_points={i+1 for i in range(len(origpoints)) if origpoints[i]!=points[i]}
    changed_normals={i for i in range(len(orignormals)) if orignormals[i]!=normals[i]}
    changed_divs={i for i in range(len(origdiv)) if origdiv[i]!=dividers[i]}
    polygon_count=0
    for newlist,oldlist in zip(cp,old):
        if not isinstance(newlist,dict) or newlist.get('cp_index')!=oldlist['cp_index']:
            raise ValueError('CP list order/identity cannot change')
        faces=newlist.get('polygons')
        if not isinstance(faces,list) or ((newlist['cp_index']==0 and faces) or
             (newlist['cp_index']!=0 and not faces)):
            raise ValueError('Invalid empty/background native CP list')
        for face in faces:
            reference=face if face in oldlist['polygons'] else None
            if isinstance(face,dict) and isinstance(face.get('vertices'),list):
                d=face.get('divider')
                if type(d)==int and 0<=d<len(dividers):
                    _p,_n=dividers[d]
                    if (set(face['vertices'])&changed_points or _n in changed_normals or d in changed_divs):
                        reference=None # inspect changed winding as well as plane
            polygons.validate_polygon(face,points,normals,dividers,reference)
            polygon_count+=1
    top=topology or tree.export_doc(rel)
    # Preserve native_tree's rigorous graph/leaf invariants while allowing geometry added
    # divider indexes. Only the range check needs a temporary normalized view.
    temporary=copy.deepcopy(top)
    for n in temporary['nodes']:
        if n.get('type')=='split':
            d=n.get('divider')
            if type(d)!=int or not (d==-1 or 0<=d<len(dividers)):
                raise ValueError('Tree divider index out of range')
            if d>=len(origdiv): n['divider']=0
    tree.validate_doc(rel,temporary)
    return {'polygons':polygon_count,'points':len(points),'normals':len(normals),
            'dividers':len(dividers),'changed_original_points':len(changed_points),
            'changed_original_normals':len(changed_normals),
            'changed_original_dividers':len(changed_divs)}

def index_lines(lines,rel,layout):
    marks={}
    for kind,pattern in [('edges',polygons.EDGES),('points',polygons.POINTS),
                         ('tree',polygons.TREE)]:
        marks[kind]=next(i for i,line in enumerate(lines) if pattern.match(line))
    marks['vectors']=next(i for i,line in enumerate(lines) if re.match(r'^\s*;\s*vectors\s*$',line,re.I))
    marks['cp']=next(i for i,line in enumerate(lines) if polygons.CP_MARK.match(line))
    marks['data']=next(i for i,line in enumerate(lines) if re.match(r'^\w+_data:\s*$',line.strip(),re.I))
    if not (marks['data']<marks['edges']<marks['points']<marks['vectors']<marks['cp']<marks['tree']<layout['first_node']):
        raise ValueError('Native table order not understood')
    records=model.scan(''.join(lines),'MDL')
    rows={k:[r['line'] for r in records if r['group']==group]
          for k,group in [('edges','edges'),('points','vertices'),('vectors','normals')]}
    rows['dividers']=[i for i in range(marks['data']+1,marks['edges']) if
             (m:=model.LINE.match(lines[i])) and m['width'].lower()=='w'
             and len(m['args'].split(','))==2]
    for k in ('dividers','edges','points','vectors'):
        if len(rows[k])!=layout['header_counts'][{'points':'NUM_PNTS','vectors':'NUM_VECTORS','edges':'NUM_EDGES','dividers':'NUM_DIVIDERS'}[k]]:
            raise ValueError(f'Native {k} source lines do not match header')
    return marks,rows

def compile_text(rel,doc,topology=None):
    topo=topology or tree.export_doc(rel)
    stats=validate_geometry(rel,doc,topo)
    orig=export_doc(rel)
    original=tree.old.original(rel)
    layout=tree.native_layout(rel)
    records=tree.compiled_records(topo)
    if all(doc[k]==orig[k] for k in ('points','normals','dividers','cp_lists')) and records==tree.original_records(layout):
        stats.update(added_edges=0,cp_delta_bytes=0,tree_delta_bytes=0,compiled_nodes=len(records))
        return original,stats
    lines=layout['lines'];marks,rows=index_lines(lines,rel,layout)
    points=doc['points'];normals=doc['normals'];dividers=doc['dividers']
    original_edges,_,_,_=polygons.source_geometry(rel)
    edges=copy.deepcopy(original_edges)
    lookup={tuple(sorted(edge)):i for i,edge in enumerate(edges)}
    cp_lines=[];cp_offsets={};cp_length=0
    for cp in doc['cp_lists']:
        cp_offsets[cp['cp_index']]=cp_length
        cp_lines.append(f"; cpnode #{cp['cp_index']}  offset {cp_length}\n")
        for f in cp['polygons']:
            refs=[];vs=f['vertices']
            for i,a in enumerate(vs):
                b=vs[(i+1)%len(vs)]
                key=tuple(sorted((a,b)))
                if key not in lookup:
                    if len(edges)>=0x8000:raise ValueError('Native edge reference capacity exceeded')
                    lookup[key]=len(edges);edges.append([a,b])
                idx=lookup[key]
                refs.append(idx|(0 if edges[idx]==[a,b] else 0x8000))
            words=[f['flags']|len(vs),f['divider'],*refs,f['color']]
            cp_lines.append('\tdc.w\t'+', '.join(f'${w:04x}' for w in words)+'\n')
            cp_length+=2*len(words)
        cp_lines.append('\tdc.w\t0\n');cp_length+=2
    oldp={key:value['number'] for key,value in layout['header_pointers'].items()}
    newp={}
    newp['dividers']=0
    newp['edges']=4*len(dividers)
    newp['points']=newp['edges']+4*len(edges)
    newp['tris']=newp['points']+6*(len(points)+len(normals))
    # Two original models include a nonstandard end-of-CP offset. Keep it.
    end_gap=oldp['tris']+layout['cp_bytes']-oldp['end of tris']
    newp['end of tris']=newp['tris']+cp_length-end_gap
    newp['tree']=(newp['tris']+cp_length+3)&~3
    newp['calculated colors']=newp['tree']+8*len(records)
    old_cp_by_offset={r['offset']:r['index'] for r in layout['cp_records']}
    node_lines=[]
    for i,r in enumerate(records):
        node_lines.append(f'\t\t\t; Node {8*i}\n')
        if r[0]=='split':
            node_lines.append(f'\tdc.w\t0, {r[1]}, {r[2]}, {r[3]}\n')
        else:
            node_lines.append(f'\tdc.w\t1, {r[1]}\n')
            node_lines.append(f'\tdc.l\t{cp_offsets[old_cp_by_offset[r[2]]]}\n')
    patch={};insert={};old={}
    for key,group,values in [('dividers','dividers',dividers),('points','points',points),('vectors','normals',normals)]:
        old[key]=orig[{'vectors':'normals'}.get(key,key)]
        if len(old[key])!=len(rows[key]):raise ValueError('Existing native table mismatch')
        for i,rowno in enumerate(rows[key]):
            if values[i]!=old[key][i]:
                # Signed decimal avoids assembler signed hex representation ambiguity.
                source=lines[rowno]
                m=model.LINE.match(source)
                if m is None:raise ValueError('Cannot patch native geometry row')
                ending='\r\n' if source.endswith('\r\n') else '\n' if source.endswith('\n') else ''
                patch[rowno]=m.group(1)+', '.join(map(str,values[i]))+m['comment'].rstrip('\r\n')+ending
        block=[]
        for i,v in enumerate(values[len(old[key]):],start=len(old[key])):
            block.append('\tdc.w\t'+', '.join(map(str,v))+f'\t; geometry {key} #{i}\n')
        insert[marks[{'dividers':'edges','points':'vectors','vectors':'cp'}[key]]]=block
    edge_add=edges[len(original_edges):]
    insert[marks['points']]=['\tdc.w\t'+', '.join(map(str,v))+f'\t; geometry edge #{i}\n'
                            for i,v in enumerate(edge_add,start=len(original_edges))]
    for name,num in [('NUM_PNTS',len(points)),('NUM_VECTORS',len(normals)),
                     ('NUM_DIVIDERS',len(dividers)),('NUM_EDGES',len(edges))]:
        entry=next(i for i,s in enumerate(lines) if (m:=HEADER_COUNT.match(s)) and m[2].upper()==name)
        if num!=layout['header_counts'][name]:
            m=re.match(r'^(\s*dc\.w\s+)\d+(\s*;\s*'+name+r'\s*)(\r?\n?)$',lines[entry],re.I)
            if not m:raise ValueError('Cannot safely patch native count')
            patch[entry]=m[1]+str(num)+m[2]+m[3]
    for key,num in newp.items():
        meta=layout['header_pointers'][key]
        if num!=meta['number']:
            m=HEADER_PTR.match(lines[meta['line']])
            if not m:raise ValueError('Cannot safely patch native relocation')
            patch[meta['line']]=m[1]+m[2]+'+'+str(num)+m[4]+m[6]
    result=[]
    for i,line in enumerate(lines):
        if i in insert:result.extend(insert[i])
        if i==marks['cp']:result.extend(cp_lines)
        if i==layout['first_node']:result.extend(node_lines)
        if marks['cp']<=i<marks['tree'] or layout['first_node']<=i<layout['after_nodes']:
            continue
        result.append(patch.get(i,line))
    blob=''.join(result).encode('latin1')
    parsed=tree.native_layout(rel,blob)
    for group,key in [('NUM_PNTS','points'),('NUM_VECTORS','normals'),('NUM_DIVIDERS','dividers'),('NUM_EDGES','edges')]:
        if parsed['header_counts'][group]!=len({'points':points,'normals':normals,'dividers':dividers,'edges':edges}[key]):
            raise ValueError('Independent native header count verification failed')
    if parsed['polygons']!=stats['polygons'] or parsed['cp_bytes']!=cp_length:
        raise ValueError('Independent CP section verification failed')
    if {k:x['number'] for k,x in parsed['header_pointers'].items() if k in newp}!=newp:
        raise ValueError('Independent pointer verification failed')
    # No silent reinterpretation: parse the emitted native arrays and faces.
    generated=model.scan(blob.decode('latin1'),'MDL')
    values={key:[r['values'] for r in generated if r['group']==group]
            for key,group in [('points','vertices'),('normals','normals'),('edges','edges')]}
    if values['points']!=points or values['normals']!=normals or values['edges']!=edges:
        raise ValueError('Native table re-decode mismatch')
    _,regenrows=index_lines(parsed['lines'],rel,parsed)
    if len(regenrows['dividers'])!=len(dividers):raise ValueError('Native dividers lost')
    for i,row in enumerate(regenrows['dividers']):
        m=model.LINE.match(parsed['lines'][row]);arr=[model.parse_int(s) for s in m['args'].split(',')]
        if arr!=dividers[i]:raise ValueError('Native divider re-decode mismatch')
    reconstructed=[]
    for cp in parsed['cp_records']:
        w=cp['words'];faces=[];i=0
        while i<len(w)-1:
            n=(w[i]&15)+3
            faces.append(polygons.decode_face(w[i:i+n],edges));i+=n
        reconstructed.append({'cp_index':cp['index'],'polygons':faces})
    if reconstructed!=doc['cp_lists']:
        raise ValueError('Compiled CP list differs from authored geometry')
    if [(n['divider'] if n['type']=='split' else n['cp_offset']) for n in parsed['nodes']] != [
         (r[1] if r[0]=='split' else cp_offsets[old_cp_by_offset[r[2]]]) for r in records]:
        raise ValueError('Native tree divider/leaf references changed')
    stats.update(added_edges=len(edge_add),cp_delta_bytes=cp_length-layout['cp_bytes'],
        tree_delta_bytes=newp['tree']-oldp['tree'],compiled_nodes=len(records),
        new_pointers=newp,cp_offsets=cp_offsets)
    return blob,stats

def geometry_probe():
    """Insert one interior point, computed normal and divider; triangulate quad."""
    rel=Path('CAR2.MDL');doc=export_doc(rel)
    original=doc['cp_lists'][1]['polygons'][0]
    vs=original['vertices']
    if len(vs)!=4:raise ValueError('Car 2 original quad changed')
    verts=doc['points']
    # Center of a quad diagonal, rounded to Jaguar 16-bit integer coordinates.
    pt=[int(round((verts[vs[0]-1][i]+verts[vs[2]-1][i])/2)) for i in range(3)]
    new_vertex=len(verts)+1
    verts.append(pt)
    raw_normal=polygons.cross(polygons.sub(verts[vs[1]-1],verts[vs[0]-1]),
                         polygons.sub(verts[vs[2]-1],verts[vs[1]-1]))
    length=polygons.norm(raw_normal)
    normal=[int(round(32767*v/length)) for v in raw_normal]
    new_normal=len(doc['normals']);doc['normals'].append(normal)
    new_divider=len(doc['dividers']);doc['dividers'].append([new_vertex-1,new_normal])
    faces=[]
    for i,a in enumerate(vs):
        face=copy.deepcopy(original)
        face['vertices']=[a,vs[(i+1)%4],new_vertex]
        face['divider']=new_divider
        faces.append(face)
    before=polygons.face_area(verts,vs)
    after=sum(polygons.face_area(verts,f['vertices']) for f in faces)
    if abs(before-after)>1e-7:raise ValueError('Probe triangulation does not conserve area')
    doc['cp_lists'][1]['polygons'][:1]=faces
    blob,stats=compile_text(rel,doc)
    folder=BASE/'probes';folder.mkdir(parents=True,exist_ok=True)
    (folder/'CAR2_full_tables.MDL').write_bytes(blob)
    (folder/'CAR2_full_tables.geometry.json').write_text(json.dumps(doc,indent=2)+'\n')
    stats.update(probe_area_before=before,probe_area_after=after,
                 probe_area_error=abs(before-after),new_point=pt,new_normal=normal,
                 new_divider=[new_vertex-1,new_normal],new_vertex_id=new_vertex)
    (folder/'geometry_probe.json').write_text(json.dumps(stats,indent=2)+'\n')
    return stats

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['export','compile','check','probe'])
    parser.add_argument('--only',action='append')
    args=parser.parse_args()
    if args.action=='probe':
        print(json.dumps(geometry_probe(),indent=2));return
    rels=[Path(r) for r in args.only] if args.only else MODELS
    report={}
    for rel in rels:
        if rel not in MODELS:raise ValueError('Unsupported model')
        path=json_path(rel)
        if args.action=='export':
            if path.exists():raise ValueError('Refusing to overwrite native authored JSON')
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text(json.dumps(export_doc(rel),indent=2)+'\n')
            stats={'exported':True}
        else:
            doc=json.loads(path.read_text())
            topo=json.loads(tree.path(rel).read_text())
            blob,stats=compile_text(rel,doc,topo)
            out=output_path(rel)
            if args.action=='compile':
                out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(blob)
            else:
                if not out.exists() or out.read_bytes()!=blob:raise ValueError('Stale compiled native geometry')
        print(args.action.upper(),rel,stats)
        report[str(rel)]=stats
    if args.action=='compile' and not args.only:
        (BASE/'geometry_index.json').write_text(json.dumps(report,indent=2)+'\n')
    print('TOTAL',args.action,len(rels))

if __name__=='__main__':main()
