#!/usr/bin/env python3
"""Original Club Drive 3D Studio ASCII authoring bridge (2026 reconstruction).

The .ASC files are original 3D Studio text, NOT Jaguar runtime geometry.
Preserve every original face/material/light/comment line. Only explicitly
changed vertex coordinates are rewritten. Exact unmodified text round trips.

Three car meshes have surviving ASC+BND+MDL triples. Their corresponding
vertices are in the *same order*. The historical `bnd2mdl -flip` transform is
X,Y,Z -> -X,Y,-Z. On deliberate ASC integer-unit edits, apply the observed
axis transform to the two fixed-topology native source JSON files (and runtime CAR2/CAR3):
  delta BND = (delta ASC Y, -delta ASC Z, -delta ASC X)
  delta MDL = (-delta ASC Y, -delta ASC Z, delta ASC X)
These are DELTAS relative to surviving originals, not a recreation of mkbnd.
We do NOT regenerate collision BSPs, face normals or material assignments.

Original format/converter context: CARS/MAKEFILE. This script is NOT original
Atari code, and its fixed-topology restrictions are intentional safeguards.
"""
from pathlib import Path
import json, hashlib, re, argparse, math, sys
import native_model_pipeline as mdl
from asset_paths import asset_file

ROOT=Path(__file__).resolve().parent.parent
BASE=ROOT/'assets/3d/geometry'
LINKED={'CARS/CAR2.ASC':'CAR2','CARS/CAR3.ASC':'CAR3','CARS/DRONE.ASC':'DRONE'}
VERTEX=re.compile(r'^(?P<front>\s*Vertex\s+(?P<index>\d+):\s+X:\s*)(?P<x>[-+\d.eE]+)(?P<yfront>\s+Y:\s*)(?P<y>[-+\d.eE]+)(?P<zfront>\s+Z:\s*)(?P<z>[-+\d.eE]+)(?P<tail>[^\r\n]*)(?P<eol>\r?\n?)$',re.I)
OBJ=re.compile(r'^\s*Named object:\s*"(.*)"',re.I)

def checksum(x):return hashlib.sha256(x).hexdigest()
def canonical_asc():
    allfiles=sorted(set(list(ROOT.glob('assets/maps/arenas/**/*.[Aa][Ss][Cc]'))+list(ROOT.glob('assets/3d/cars/**/*.[Aa][Ss][Cc]'))+list(ROOT.glob('assets/maps/house/**/*.[Aa][Ss][Cc]'))+list(ROOT.glob('assets/maps/race/**/*.[Aa][Ss][Cc]'))))
    chosen={}
    for p in allfiles:
        # Keep the original source-relative identity in JSON and template names.
        kind=next(kind for kind,sub in [('ARENAS','maps/arenas'),('CARS','3d/cars'),('HOUSE','maps/house'),('RACEWRLD','maps/race')] if p.is_relative_to(ROOT/'assets'/sub))
        rel=Path(kind)/p.relative_to(ROOT/'assets'/{'ARENAS':'maps/arenas','CARS':'3d/cars','HOUSE':'maps/house','RACEWRLD':'maps/race'}[kind])
        key=str(rel).casefold()
        if key not in chosen or p.name.isupper():chosen[key]=rel
    return sorted(chosen.values(), key=lambda x:str(x).casefold())

def path_doc(rel):return BASE/'json'/rel.with_suffix(rel.suffix+'.json')
def path_tpl(rel):return BASE/'templates'/rel

def parse_text(txt):
    result=[];obj=''
    for line,src in enumerate(txt.splitlines(keepends=True)):
        m=OBJ.match(src)
        if m:obj=m.group(1)
        v=VERTEX.match(src)
        if v:
            result.append({'line':line,'mesh':obj,'index':int(v['index']), 'xyz':[float(v[k]) for k in ('x','y','z')]})
    return result

def export_one(rel):
    raw=asset_file(rel).read_bytes()
    t=path_tpl(rel);t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(raw)
    verts=parse_text(raw.decode('latin1'))
    if not verts:raise ValueError(f'{rel}: no ASC vertices')
    j={'schema':'club-asc-vertex','original':str(rel),'template_sha256':checksum(raw),
       'notes':['2026 reconstruction. Faces/materials retain surviving text; edit only xyz values.',
                'CARS/CAR2, CAR3, DRONE are linked to native JSON via fixed-topology vertex deltas.',
                'Other .ASC sources are editable ASCII sources, NOT yet linked to game world resources.'],
       'vertices':verts,'lowercase_alias':bool(asset_file(Path(str(rel).lower())).is_file() and asset_file(Path(str(rel).lower())).read_bytes()==raw)}
    out=path_doc(rel);out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(j,indent=2)+'\n')
    return len(verts)

def gen_asc(rel,doc):
    original=path_tpl(rel).read_bytes()
    if doc.get('schema')!='club-asc-vertex' or doc.get('original')!=str(rel) or doc.get('template_sha256')!=checksum(original):raise ValueError(f'{rel}: template provenance mismatch')
    text=original.decode('latin1');lines=text.splitlines(keepends=True)
    source=parse_text(text)
    if len(source)!=len(doc['vertices']):raise ValueError(f'{rel}: changed vertex count')
    moves=[];count=0
    for vertex_index,(baseline,edited) in enumerate(zip(source,doc['vertices'])):
        if baseline['line']!=edited['line'] or baseline['index']!=edited['index'] or baseline['mesh']!=edited['mesh']:raise ValueError(f'{rel}: vertex identity mismatch')
        xyz=edited['xyz']
        if len(xyz)!=3 or any(type(x) not in (int,float) or not math.isfinite(x) for x in xyz):raise ValueError(f'{rel}: invalid vertex coordinate')
        dif=[float(x)-y for x,y in zip(xyz,baseline['xyz'])]
        if max(abs(x) for x in dif)<1e-9:continue
        m=VERTEX.match(lines[edited['line']]);assert m
        def fmt(x):return f'{x:.6f}'.rstrip('0').rstrip('.') if abs(x)<1e8 else f'{x:.6f}'
        lines[edited['line']]=m['front']+fmt(xyz[0])+m['yfront']+fmt(xyz[1])+m['zfront']+fmt(xyz[2])+m['tail']+m['eol']
        moves.append((vertex_index,dif));count+=1
    return ''.join(lines).encode('latin1'),source,moves

def plan_native(rel,original_rows,changes,prev_sync):
    """Plan changes without writing; reject any manual/native conflict.

    Updates each original vertex at most once, without modifying divider lists,
    normals, BSP topology, or polygon flags. Integer-unit displacements only.
    """
    name=LINKED.get(str(rel))
    if not name:return [],0
    # Leave independent models native edits untouched if ASC contributes no
    # movement and no previous ASC-derived movement needs to be reverted.
    if not changes and not any(
        [v for v in prev_sync.get(str(p),{}).values()] !=
        [r['values'] for r in mdl.scan(mdl.template_file(p).read_bytes().decode('latin1'),p.suffix[1:]) if r['group']=='vertices']
        for p in ([Path('CARS')/(name+'.BND'),Path('CARS')/(name+'.MDL')]+([Path(name+'.MDL')] if mdl.template_file(Path(name+'.MDL')).exists() else []))
        if str(p) in prev_sync
    ):
        return [],0
    rows=[r for r in original_rows]
    displacements={}
    for idx,ds in changes:
        rounded=[int(round(x)) for x in ds]
        if any(abs(x-n)>1e-4 for x,n in zip(ds,rounded)):
            raise ValueError(f'{rel}: edited ASC delta must be whole Jaguar units for native link: {ds}')
        if max(abs(x) for x in rounded)>2:
            raise ValueError(f'{rel}: delta exceeds conservative 2-unit collision safety limit; native BSP cannot be regenerated')
        dx,dy,dz=rounded
        displacements[idx]=(dy,-dz,-dx)
    # play.s includes *top-level* car2.mdl/car3.mdl aliases. The originals
    # share vertex order/positions with CARS/*.MDL but their surface records
    # may differ (findbg/mkbnd processing). Update ONLY the vertex rows there.
    # That is what carries an ASC car edit into the runnable cartridge.
    targets=[Path('CARS')/(name+'.BND'),Path('CARS')/(name+'.MDL')]
    runtime=Path(name+'.MDL')
    if mdl.template_file(runtime).exists():
        targets.append(runtime)
    tasks=[]
    for p in targets:
        ext=p.suffix
        path=mdl.authoring_file(p)
        d=json.loads(path.read_text())
        tpl=mdl.scan(mdl.template_file(p).read_bytes().decode('latin1'),ext[1:])
        bases=[r['values'] for r in tpl if r['group']=='vertices']
        vertices=d['groups']['vertices']
        if len(bases)!=len(rows) or len(vertices)!=len(rows):raise ValueError(f'{name}: ASC/native vertex count mismatch')
        newvals=[]
        for idx,(base,edit) in enumerate(zip(bases,vertices)):
            # MDL follows surviving -flip option; no guessed transformations.
            if ext=='.MDL':
                b=mdl.scan(mdl.template_file(Path('CARS')/(name+'.BND')).read_bytes().decode('latin1'),'BND')
                v=[r['values'] for r in b if r['group']=='vertices'][idx]
                if base!=[-v[0],v[1],-v[2]]:raise ValueError(f'{name}: -flip relationship invalid at {idx}')
            move=displacements.get(idx,(0,0,0))
            if ext=='.MDL':move=(-move[0],move[1],-move[2])
            want=[base[i]+move[i] for i in range(3)]
            previous=prev_sync.get(str(p),{}).get(str(idx),base)
            if edit['values'] not in (base,previous,want):
                raise ValueError(f'{name}: conflicting manual edit in {p} vertex {idx}; refusing overwrite')
            if any(abs(x)>32767 for x in want):raise ValueError('Jaguar vertex signed-word overflow')
            newvals.append(want)
        for e,v in zip(vertices,newvals):e['values']=v
        tasks.append((path,d,str(p),{str(i):v for i,v in enumerate(newvals)}))
    return tasks,len(displacements)

def run_compile(check=False):
    changed_native={};outputs=[];edits=0
    syncfile=BASE/'last_sync.json'
    last=json.loads(syncfile.read_text()) if syncfile.exists() else {}
    new_sync=dict(last)
    # All validation/planning before any source overwrite.
    for rel in canonical_asc():
        f=path_doc(rel)
        if not f.exists():raise FileNotFoundError(f'Missing authoring JSON {f}; run export')
        d=json.loads(f.read_text());target,original,changes=gen_asc(rel,d)
        outputs.append((asset_file(rel),target))
        # Keep exact-case alias in sync only if it existed in original sources.
        lower=asset_file(Path(str(rel).lower()))
        if lower!=asset_file(rel) and d.get('lowercase_alias',False) and lower.is_file():outputs.append((lower,target))
        tasks,n=plan_native(rel,original,changes,last)
        for p,obj,key,values in tasks:
            changed_native[p]=obj
            new_sync[key]=values
        edits+=n
    if check:
        for p,raw in outputs:
            if p.read_bytes()!=raw:raise ValueError(f'ASC output stale: {p}')
        for p,obj in changed_native.items():
            if json.loads(p.read_text())!=obj:raise ValueError(f'Native JSON out of sync: {p}')
        print(f'CHECK: {len(canonical_asc())} ASC sources / {edits} linked edits / {len(changed_native)} native documents valid')
        return
    for p,raw in outputs:p.write_bytes(raw)
    for p,obj in changed_native.items():p.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
    syncfile.write_text(json.dumps(new_sync,indent=2)+'\n')
    print(f'COMPILED: {len(canonical_asc())} ASC authoring sources; {edits} native vertex edits; {len(changed_native)} linked native JSON documents')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=('export','compile','check','stats'))
    args=parser.parse_args()
    if args.command=='export':
        counts=[]
        for rel in canonical_asc():counts.append((str(rel),export_one(rel)))
        (BASE/'asc_index.json').write_text(json.dumps({'sources':counts, 'total_vertices':sum(n for _,n in counts)},indent=2)+'\n')
        print('EXPORTED',len(counts),'ASC files',sum(n for _,n in counts),'vertices')
    elif args.command=='stats':
        d=json.loads((BASE/'asc_index.json').read_text());print(len(d['sources']),'ASC files',d['total_vertices'],'vertices')
    else:run_compile(args.command=='check')
if __name__=='__main__':main()
