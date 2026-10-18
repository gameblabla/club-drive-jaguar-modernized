#!/usr/bin/env python3
"""2026 reconstruction: isolated authoring for three surviving car .BND intermediates.
Not a Jaguar runtime world .BND exporter; no solid/empty ownership assumptions.
"""
from asset_paths import asset_file
import argparse, copy, hashlib, json, re
from collections import defaultdict, deque
from pathlib import Path
import native_collision as geometry
import native_model_pipeline as model
ROOT=Path(__file__).resolve().parent.parent
BASE=ROOT/'assets/3d/bounds'
MODELS=[Path('CARS/CAR2.BND'),Path('CARS/CAR3.BND'),Path('CARS/DRONE.BND')]
HEAD=re.compile(r'^(size(Divider|Edge|Point|Vector|Color|CPs)Table\s+EQU\s+)(\d+)(\s*)$',re.I|re.M)
LABEL=re.compile(r'^([A-Za-z_][A-Za-z_0-9]*):\s*$',re.M)

def decode(text):
    marks={m[1].lower():m.start() for m in LABEL.finditer(text)}
    if not all(x in marks for x in ('dividers','edges','points','colors','tris')) or not (marks['dividers']<marks['edges']<marks['points']<marks['colors']<marks['tris']):
        raise ValueError('Unexpected BND section layout')
    sizes={m[2].lower():int(m[3]) for m in HEAD.finditer(text)}
    if set(sizes)!={'divider','edge','point','vector','color','cps'}:raise ValueError('Missing BND size declarations')
    rows=model.scan(text,'BND')
    arr=lambda key:[r['values'] for r in rows if r['group']==key]
    tables={'points':arr('vertices'),'normals':arr('normals'),'dividers':arr('collision_dividers'),'edges':arr('edges')}
    for size,key in (('point','points'),('vector','normals'),('divider','dividers'),('edge','edges')):
        if sizes[size]!=len(tables[key]):raise ValueError(f'BND count mismatch {key}')
    color_lines=[l for l in text[marks['colors']:marks['tris']].splitlines() if (m:=model.LINE.match(l)) and m['width'].lower()=='w']
    if len(color_lines)!=sizes['color']:raise ValueError('BND color count mismatch')
    cps=[];faces=[]
    for line in text[marks['tris']:].splitlines():
        m=model.LINE.match(line)
        if not m or m['width'].lower()!='w':continue
        words=[model.parse_int(s) for s in m['args'].split(',')]
        if words==[0]:
            cps.append({'cp_index':len(cps),'polygons':faces});faces=[]
        else:
            if len(words)<6 or (words[0]&15)+3!=len(words):raise ValueError('Invalid BND CP record')
            faces.append(geometry.decode_face(words,tables['edges']))
    if faces or not cps:raise ValueError('Missing BND surface terminator')
    return dict(**tables,cp_lists=cps,sizes=sizes,marks=marks)

def original(rel):
    if rel not in MODELS:raise ValueError('Unsupported BND original')
    return asset_file(rel).read_bytes().decode('latin1')

def export_doc(rel):
    t=original(rel);d=decode(t)
    return {'schema':'club-bnd-geometry','source_model':str(rel),
      'source_template_sha256':hashlib.sha256(t.encode('latin1')).hexdigest(),
      'provenance':'Surviving original car BND intermediate; 2026 reconstruction',
      'safety':'Not the lost Atari world exporter; experimental data is never linked into runtime ROM',
      **{k:copy.deepcopy(d[k]) for k in ('points','normals','dividers','cp_lists')}}

def validate(rel,doc):
    orig=export_doc(rel);bas=decode(original(rel))
    for k in ('schema','source_model','source_template_sha256'):
        if doc.get(k)!=orig[k]:raise ValueError('BND template mismatch: '+k)
    for key,arity in (('points',3),('normals',3),('dividers',2)):
        rows=doc.get(key)
        if not isinstance(rows,list) or not len(orig[key])<=len(rows)<=32767:
            raise ValueError('Cannot remove original BND '+key)
        if any(type(r)!=list or len(r)!=arity or any(type(v)!=int or v < -32768 or v > 32767 for v in r) for r in rows):
            raise ValueError('Native signed word overflow: '+key)
    points,normals,dividers=(doc[k] for k in ('points','normals','dividers'))
    for n in normals:
        if not 32700<=geometry.norm(n)<=32820:raise ValueError('Non-unit BND normal')
    for p,n in dividers:
        if not 0<=p<len(points) or not 0<=n<len(normals):raise ValueError('BND divider index invalid')
    cps=doc.get('cp_lists')
    if not isinstance(cps,list) or len(cps)!=len(orig['cp_lists']):raise ValueError('BND CP grouping changed')
    touched_pts={i+1 for i,v in enumerate(orig['points']) if v!=points[i]}
    touched_normals={i for i,v in enumerate(orig['normals']) if v!=normals[i]}
    touched_dividers={i for i,v in enumerate(orig['dividers']) if v!=dividers[i]}
    polys=0
    for cp,base in zip(cps,orig['cp_lists']):
        if not isinstance(cp,dict) or cp.get('cp_index')!=base['cp_index'] or not isinstance(cp.get('polygons'),list):raise ValueError('Invalid BND CP identity')
        if bool(cp['polygons']) != bool(base['polygons']):raise ValueError('BND empty/nonempty group changed')
        for face in cp['polygons']:
            same=face if face in base['polygons'] else None
            if isinstance(face,dict) and type(face.get('divider'))==int and 0<=face['divider']<len(dividers):
                p,n=dividers[face['divider']]
                if set(face.get('vertices',[]))&touched_pts or n in touched_normals or face['divider'] in touched_dividers:same=None
            geometry.validate_polygon(face,points,normals,dividers,same)
            polys+=1
    return {'model':str(rel),'points':len(points),'normals':len(normals),'dividers':len(dividers),
            'original_edges':len(bas['edges']),'cp_groups':len(cps),'polygons':polys}

def word(vals,hexa=False):
    return '\tdc.w\t'+', '.join((f'${v&65535:04x}' if hexa else str(v)) for v in vals)+'\n'

def compile_text(rel,doc):
    stats=validate(rel,doc);old=export_doc(rel);source=original(rel)
    if all(doc[k]==old[k] for k in ('points','normals','dividers','cp_lists')):
        return source.encode('latin1'),dict(stats,new_edges=0,changed=False)
    parsed=decode(source);edges=copy.deepcopy(parsed['edges'])
    lookup={tuple(sorted(x)):i for i,x in enumerate(edges)}
    # Preserve native edge-reference *identity* for unedited polygons.
    # Some historical BND files contain duplicate edge endpoint pairs;
    # re-encoding them by endpoints alone silently changes the assembler bytes.
    saved=defaultdict(deque);cp_id=0
    for line in source[parsed['marks']['tris']:].splitlines():
        m=model.LINE.match(line)
        if not m or m['width'].lower()!='w':continue
        words=[model.parse_int(x) for x in m['args'].split(',')]
        if words==[0]:cp_id+=1;continue
        face=geometry.decode_face(words,parsed['edges'])
        saved[(cp_id,json.dumps(face,sort_keys=True))].append(words)
    cp_lines=[]
    for cp in doc['cp_lists']:
        for face in cp['polygons']:
            prior=saved[(cp['cp_index'],json.dumps(face,sort_keys=True))]
            if prior:
                cp_lines.append(word(prior.popleft(),True));continue
            refs=[];vs=face['vertices']
            for a,b in zip(vs,vs[1:]+vs[:1]):
                key=tuple(sorted((a,b)))
                if key not in lookup:
                    if len(edges)>=32768:raise ValueError('BND direction-bit edge capacity reached')
                    lookup[key]=len(edges);edges.append([a,b])
                idx=lookup[key]
                refs.append(idx | (0x8000 if edges[idx]!=[a,b] else 0))
            cp_lines.append(word([face['flags']|len(vs),face['divider'],*refs,face['color']],True))
        cp_lines.append('\tdc.w\t0\n')
    marks=parsed['marks'];sizes={'divider':len(doc['dividers']),'edge':len(edges),'point':len(doc['points']),'vector':len(doc['normals'])}
    def repl(m):return m[1]+str(sizes.get(m[2].lower(),int(m[3])))+m[4]
    prefix=HEAD.sub(repl,source[:marks['dividers']])
    mid='dividers:\n'+''.join(map(word,doc['dividers']))
    mid+='edges:\n'+''.join(map(word,edges))
    mid+='points:\n'+''.join(map(word,doc['points']))
    mid+=f'; {len(doc["normals"])} vectors\n'+''.join(map(word,doc['normals']))
    suffix=source[marks['colors']:marks['tris']]
    result=prefix+mid+suffix+'tris:\n'+''.join(cp_lines)
    rebuilt=decode(result)
    for k in ('points','normals','dividers','cp_lists'):
        if rebuilt[k]!=doc[k]:raise ValueError('Compiled BND re-decode mismatch: '+k)
    if rebuilt['edges']!=edges:raise ValueError('Compiled BND edge re-decode mismatch')
    for k in ('color','cps'):
        if rebuilt['sizes'][k]!=parsed['sizes'][k]:raise ValueError('Undocumented size declaration mutated')
    stats.update(new_edges=len(edges)-len(parsed['edges']),changed=True)
    return result.encode('latin1'),stats

def probe():
    rel=MODELS[0];doc=export_doc(rel);f=doc['cp_lists'][1]['polygons'][0]
    if len(f['vertices'])!=4:raise ValueError('Source Car2 quad no longer at probe location')
    vs=f['vertices'];p=doc['points']
    pt=[round((p[vs[0]-1][i]+p[vs[2]-1][i])/2) for i in range(3)]
    p.append(pt);point_id=len(p)
    raw=geometry.cross(geometry.sub(p[vs[1]-1],p[vs[0]-1]),geometry.sub(p[vs[2]-1],p[vs[1]-1]))
    mag=geometry.norm(raw);n=[round(v*32767/mag) for v in raw]
    doc['normals'].append(n);divider=len(doc['dividers']);doc['dividers'].append([point_id-1,len(doc['normals'])-1])
    tris=[]
    for i,v in enumerate(vs):
        face=copy.deepcopy(f);face['vertices']=[v,vs[(i+1)%4],point_id];face['divider']=divider;tris.append(face)
    area=geometry.face_area(p,vs);newarea=sum(geometry.face_area(p,tri['vertices']) for tri in tris)
    if abs(area-newarea)>1e-7:raise ValueError('BND fan changes area')
    doc['cp_lists'][1]['polygons'][:1]=tris
    blob,stats=compile_text(rel,doc)
    path=BASE/'probes';path.mkdir(parents=True,exist_ok=True)
    (path/'CAR2_edited.BND').write_bytes(blob)
    (path/'CAR2_edited.geometry.json').write_text(json.dumps(doc,indent=2)+'\n')
    stats.update(original_area=area,edited_area=newarea,area_difference=abs(area-newarea),added_point=pt,added_normal=n)
    (path/'probe.json').write_text(json.dumps(stats,indent=2)+'\n')
    return stats

def main():
    a=argparse.ArgumentParser(description=__doc__);a.add_argument('action',choices=['export','compile','check','probe']);a.add_argument('--only',action='append');q=a.parse_args()
    if q.action=='probe':print(json.dumps(probe(),indent=2));return
    names=[Path(x) for x in q.only] if q.only else MODELS
    manifest={}
    for rel in names:
        if rel not in MODELS:raise ValueError('Unsupported intermediate BND')
        path=BASE/'json'/rel.with_suffix('.BND.geometry.json')
        if q.action=='export':
            if path.exists():raise ValueError('Refusing to overwrite authored JSON')
            path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(export_doc(rel),indent=2)+'\n');stats={'exported':True}
        else:
            doc=json.loads(path.read_text());blob,stats=compile_text(rel,doc)
            dest=BASE/'generated'/rel
            if q.action=='compile':dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(blob)
            elif not dest.exists() or dest.read_bytes()!=blob:raise ValueError('Stale BND output: '+str(rel))
        manifest[str(rel)]=stats
        print(q.action.upper(),rel,stats)
    if q.action=='compile' and not q.only:(BASE/'index.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('TOTAL',len(names))
if __name__=='__main__':main()
