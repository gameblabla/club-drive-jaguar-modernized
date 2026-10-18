#!/usr/bin/env python3
"""Geometry-driven, reversible *authoring* BSP for original Club Drive ASC meshes.

2026 reconstruction; NOT the historical Atari mkbnd program or Jaguar BSP.

This is a real geometry partition, not a rewrite of the original MDL node table:
choose deterministic axis planes, clip crossing faces to both half-spaces,
retain original face/material identity, verify summed polygon area, and expose
nodes and fragments as documented JSON and PNG diagrams. Native .BND/.MDL
collision trees are NEVER overwritten. Those need different topology and
polygon-list serialization and do not follow from this spatial structure.

Input is the existing ASC authoring JSON + original text template, so edited
geometry is reflected in these 2026 BSPs even before the Jaguar builder runs.
Only geometric meshes ('Tri-mesh') participate, not lights or cameras.
"""
import argparse, hashlib, json, math, re, sys
from collections import defaultdict
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent.parent
BASE=ROOT/'assets/bsp/partitions'
sys.path.insert(0,str(ROOT/'build'))
import asc_authoring as asc

NAMED=re.compile(r'^\s*Named object:\s*"(.*)"',re.I)
MESH=re.compile(r'^\s*Tri-mesh,\s*Vertices:\s*(\d+)\s+Faces:\s*(\d+)',re.I)
VERT=re.compile(r'^\s*Vertex\s+(\d+):\s*X:\s*([-+\d.Ee]+)\s+Y:\s*([-+\d.Ee]+)\s+Z:\s*([-+\d.Ee]+)',re.I)
FACE=re.compile(r'^\s*Face\s+(\d+):\s*A:(\d+)\s+B:(\d+)\s+C:(\d+)',re.I)
MAT=re.compile(r'^\s*Material:\s*"(.*)"',re.I)


def read_meshes(text):
    meshes=[];current=None;pending_name='';active=False;last_face=None
    for line in text.splitlines():
        n=NAMED.match(line)
        if n:
            pending_name=n[1];current=None;active=False;last_face=None;continue
        m=MESH.match(line)
        if m:
            current={'name':pending_name,'vertices':[], 'faces':[], 'expected_vertices':int(m[1]),'expected_faces':int(m[2])}
            meshes.append(current);active=True;last_face=None;continue
        if not active:continue
        v=VERT.match(line)
        if v:
            if int(v[1])!=len(current['vertices']):raise ValueError(f'{pending_name}: discontinuous vertex ID {v[1]}')
            xyz=tuple(float(v[k]) for k in (2,3,4))
            if not all(math.isfinite(z) for z in xyz):raise ValueError(f'{pending_name}: nonfinite vertex')
            current['vertices'].append(xyz);continue
        f=FACE.match(line)
        if f:
            if int(f[1])!=len(current['faces']):raise ValueError(f'{pending_name}: discontinuous face ID {f[1]}')
            ids=tuple(int(f[k]) for k in (2,3,4))
            current['faces'].append({'id':int(f[1]),'indices':ids,'material':''});last_face=current['faces'][-1];continue
        mat=MAT.match(line)
        if mat and last_face is not None:last_face['material']=mat[1]
    for m in meshes:
        if len(m['vertices'])!=m['expected_vertices'] or len(m['faces'])!=m['expected_faces']:
            raise ValueError(f"{m['name']}: expected {m['expected_vertices']} vertices/{m['expected_faces']} faces, found {len(m['vertices'])}/{len(m['faces'])}")
        for face in m['faces']:
            if any(i<0 or i>=len(m['vertices']) for i in face['indices']):raise ValueError(f"{m['name']}: invalid face index")
    return meshes


def area(poly):
    a=poly[0]; total=0.
    # Triangle fan (works for clipped triangles, which remain convex).
    for i in range(1,len(poly)-1):
        b,c=poly[i],poly[i+1]
        u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)]
        x=u[1]*v[2]-u[2]*v[1];y=u[2]*v[0]-u[0]*v[2];z=u[0]*v[1]-u[1]*v[0]
        total+=math.sqrt(x*x+y*y+z*z)/2
    return total


def clip(poly,axis,pivot,positive):
    """Sutherland-Hodgman clip against a 3D axis-aligned halfspace."""
    out=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        da=a[axis]-pivot;db=b[axis]-pivot
        ia=da>=-1e-9 if positive else da<=1e-9
        ib=db>=-1e-9 if positive else db<=1e-9
        if ia:out.append(a)
        if ia!=ib:
            t=da/(da-db)
            out.append(tuple(a[k]+t*(b[k]-a[k]) for k in range(3)))
    # Drop zero-length consecutive edges created when the triangle lies on a plane.
    dedup=[]
    for p in out:
        if not dedup or max(abs(p[k]-dedup[-1][k]) for k in range(3))>1e-8:dedup.append(p)
    if len(dedup)>1 and max(abs(dedup[0][k]-dedup[-1][k]) for k in range(3))<=1e-8:dedup.pop()
    return dedup if len(dedup)>=3 and area(dedup)>1e-9 else []


def make_tree(mesh,leaf_limit=12,max_depth=12):
    faces=mesh['faces'];vertices=mesh['vertices']
    polys=[];orig_area=defaultdict(float)
    for face in faces:
        poly=[vertices[i] for i in face['indices']]
        a=area(poly)
        if a<=1e-10:continue # Original zero-area faces are not collision surfaces.
        orig_area[face['id']]+=a
        polys.append({'source_face':face['id'],'material':face['material'],'vertices':poly})
    original=len(polys);nodes=[];fragments=[]
    def branch(items,depth):
        idx=len(nodes);nodes.append(None)
        # Axis is chosen from centroid spread; a BSP plane lies between two
        # distinct centroid values, not through an arbitrary face polygon.
        centers=[[sum(v[k] for v in p['vertices'])/len(p['vertices']) for k in range(3)] for p in items]
        spans=[max(c[k] for c in centers)-min(c[k] for c in centers) for k in range(3)] if centers else [0]*3
        axis=max(range(3),key=lambda k:spans[k])
        can_split=depth<max_depth and len(items)>leaf_limit and spans[axis]>1e-8
        if can_split:
            vals=sorted(set(c[axis] for c in centers))
            mid=len(vals)//2
            if mid>=1:
                pivot=(vals[mid-1]+vals[mid])/2
                neg=[];pos=[]
                for p in items:
                    vs=p['vertices']
                    lo=min(v[axis] for v in vs);hi=max(v[axis] for v in vs)
                    if hi<=pivot:neg.append(p)
                    elif lo>=pivot:pos.append(p)
                    else:
                        a=clip(vs,axis,pivot,False);b=clip(vs,axis,pivot,True)
                        if a:neg.append({**p,'vertices':a})
                        if b:pos.append({**p,'vertices':b})
                # Stop unhelpful splits and pathological fragment amplification.
                if neg and pos and max(len(neg),len(pos))<len(items)*2 and len(neg)+len(pos)<=len(items)*2.5:
                    nodes[idx]={'type':'split','axis':'XYZ'[axis],'plane':pivot,'negative':None,'positive':None,'depth':depth}
                    nodes[idx]['negative']=branch(neg,depth+1)
                    nodes[idx]['positive']=branch(pos,depth+1)
                    return idx
        start=len(fragments)
        fragments.extend(items)
        nodes[idx]={'type':'leaf','depth':depth,'start':start,'count':len(items)}
        return idx
    if polys:branch(polys,0)
    # Audit surface-area conservation for every original triangle. An ordinary
    # indexed BSP cannot prove this; test the actual fragment geometry.
    summed=defaultdict(float)
    for p in fragments:summed[p['source_face']]+=area(p['vertices'])
    errors={k:abs(summed[k]-v)/v for k,v in orig_area.items() if abs(summed[k]-v)>max(1e-5,v*1e-6)}
    if errors:raise ValueError(f"{mesh['name']}: clipping does not preserve area for {len(errors)} faces, max={max(errors.values())}")
    return {'name':mesh['name'],'source_vertices':len(vertices),'source_faces':len(faces),'nondegenerate_faces':original,
            'nodes':nodes,'fragments':fragments,'area_error_max':max([abs(summed[k]-v)/v for k,v in orig_area.items()],default=0.0)}


def validate_tree(tree):
    nodes=tree['nodes'];frags=tree['fragments'];reachable=set()
    def visit(idx, chain, bounds):
        if idx in chain or idx in reachable or idx<0 or idx>=len(nodes):raise ValueError('BSP cycle or illegal node reference')
        reachable.add(idx);n=nodes[idx]
        if n['type']=='split':
            axis='XYZ'.index(n['axis']);p=n['plane']
            visit(n['negative'],chain|{idx},bounds+[(axis,p,False)])
            visit(n['positive'],chain|{idx},bounds+[(axis,p,True)])
        elif n['type']=='leaf':
            start=n['start'];count=n['count']
            if start<0 or count<0 or start+count>len(frags):raise ValueError('Invalid fragment interval')
            for q in frags[start:start+count]:
                for ax,p,pos in bounds:
                    for v in q['vertices']:
                        if (v[ax]<p-1e-5 if pos else v[ax]>p+1e-5):raise ValueError('Fragment outside ancestor halfspace')
        else:raise ValueError('Invalid node type')
    if nodes:visit(0,set(),[])
    if len(reachable)!=len(nodes):raise ValueError('Unreachable nodes')
    if sum(n['count'] for n in nodes if n['type']=='leaf')!=len(frags):raise ValueError('Fragment count mismatch')
    return len(nodes)


def build(rel, leaf_limit=12,max_depth=12):
    doc=json.loads(asc.path_doc(rel).read_text())
    source,_,_=asc.gen_asc(rel,doc)
    meshes=read_meshes(source.decode('latin1'))
    generated=[make_tree(m,leaf_limit,max_depth) for m in meshes if m['faces']]
    for tree in generated:validate_tree(tree)
    result={'schema':'club-geometry-bsp','original':str(rel),'generated_from_asc_sha256':hashlib.sha256(source).hexdigest(),
            'provenance':'2026 geometry-derived BSP, NOT byte-compatible Jaguar .BND/.MDL or original mkbnd',
            'limitations':['New geometry-based collision BSP only; existing runtime collision trees are not replaced.',
                           'No native divider normals, BSP CP records, polygon flags, or Jaguar linker offsets generated.'],
            'meshes':generated}
    # Normalize tuples to JSON arrays for deterministic semantic check.
    return json.loads(json.dumps(result))


def path(rel):return BASE/'json'/rel.with_suffix(rel.suffix+'.geometry_bsp.json')

def render(rel, doc):
    meshes=doc['meshes'];W=1100;H=100+max(1,len(meshes))*25
    H=min(2200,max(280,H))
    im=Image.new('RGB',(W,H),(250,251,252));draw=ImageDraw.Draw(im)
    draw.text((25,18),f'{rel}  —  2026 geometry-generated BSP preview',fill=(23,37,53))
    totals=(sum(len(m['nodes']) for m in meshes),sum(len(m['fragments']) for m in meshes))
    draw.text((25,41),f'{len(meshes)} meshes | {totals[0]} nodes | {totals[1]} clipped fragments; NOT native Jaguar collision records',fill=(60,75,90))
    for i,m in enumerate(meshes[:max(0,(H-85)//25)]):
        y=80+i*25
        splits=sum(n['type']=='split' for n in m['nodes'])
        draw.text((32,y),f"{m['name'][:38]:38}  {m['nondegenerate_faces']:4} faces  {splits:3} splits  {len(m['fragments']):5} fragments",fill=(41,62,80))
    p=BASE/'previews'/rel.with_suffix('.bsp.png');p.parent.mkdir(parents=True,exist_ok=True);im.save(p)


def run(action, limit=None):
    files=asc.canonical_asc()
    if limit:files=[r for r in files if str(r) in limit]
    result={};count=0
    for rel in files:
        doc=build(rel)
        if action=='check':
            p=path(rel)
            if not p.exists() or json.loads(p.read_text())!=doc:raise ValueError(f'{rel}: geometry BSP output missing/stale; run compile')
        else:
            p=path(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(doc,indent=2)+'\n')
            render(rel,doc)
        res={'meshes':len(doc['meshes']),'faces':sum(x['source_faces'] for x in doc['meshes']),
             'nodes':sum(len(x['nodes']) for x in doc['meshes']),
             'fragments':sum(len(x['fragments']) for x in doc['meshes']),
             'worst_relative_area_error':max((x['area_error_max'] for x in doc['meshes']),default=0.0)}
        result[str(rel)]=res;count+=1
        print(f'{action.upper():7} {rel}  {res}')
    # A filtered edit probe must not destroy the 93-source manifest.
    if action!='check' and not limit:(BASE/'index.json').write_text(json.dumps(result,indent=2)+'\n')
    print('COMPLETE',action,'files',count,'faces',sum(r['faces'] for r in result.values()),'nodes',sum(r['nodes'] for r in result.values()))
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('action',choices=('compile','check'))
    p.add_argument('--only',action='append',help='Restrict to a path like CARS/CAR2.ASC')
    args=p.parse_args()
    run(args.action,args.only)
