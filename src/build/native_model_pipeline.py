#!/usr/bin/env python3
"""Club Drive native model reconstruction (2026; NOT original Atari code).

Source provenance: Jaguar .MDL/.BND text in the surviving CLUB archive and
MODEL.DOC, BNDHEAD.H, BNDHEAD.INC. Editable JSON fields represent the true
native word arrays, including edge-index polygons; OBJ is inspection-only.
Original compiler/collision-tree generation is not claimed or simulated.

The original source text is saved as a *template*, including its Atari
comments, labels, pointer expressions and tree nodes. On an unchanged JSON
input the emitted .MDL/.BND is exactly that original text; edited vertices,
edges, normals, collision dividers and surfaces replace only their native
numeric operands. All pointer expressions and collision tree nodes survive.
"""
from asset_paths import asset_file
import argparse, hashlib, json, re, shutil
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'assets/3d/native_models'
EXTENSIONS = {'.MDL', '.BND'}
HEX = re.compile(r'^-?\$[\da-fA-F]+$')
INT = re.compile(r'^-?(?:\d+|0x[\da-fA-F]+)$')
LINE = re.compile(r'^(\s*dc\.(?P<width>w|l)\s+)(?P<args>[^;\r\n]+)(?P<comment>.*)$', re.I)

def parse_int(s):
    s=s.strip()
    if HEX.fullmatch(s):
        return (-1 if s.startswith('-') else 1)*int(s.lstrip('-')[1:],16)
    if INT.fullmatch(s): return int(s,0) if s.lower().startswith('0x') else int(s)
    raise ValueError(s)

def scan(text, kind):
    """Identify native array records without interpreting pointer expressions."""
    rows=[]; section=None
    for lineno, line in enumerate(text.splitlines(keepends=True)):
        x=line.strip().lower()
        if kind=='MDL':
            if re.match(r'^;\s*edges\b',x): section='edges'
            elif re.match(r'^;\s*points\b',x): section='points'
            elif re.match(r'^;\s*vectors\b',x): section='vectors'
            elif re.match(r'^;\s*cpnode\b',x): section='surfaces'
            elif re.match(r'^;\s*colors\b',x): section='colors'
            # Some MDL files use an explicit label instead of a comment.
        else:
            if x=='dividers:':section='dividers'
            elif x=='edges:':section='edges'
            elif x=='points:':section='points'
            elif x=='vectors:' or re.match(r'^;\s*\d+\s+vectors\b',x):section='vectors'
            elif x=='colors:':section='colors'
            elif x=='tris:':section='surfaces'
            elif x=='tree:':section='tree'
            elif x=='textures:':section='textures'
        if x in ('points:','edges:','vectors:','tris:','colors:'):
            section={'tris:':'surfaces'}.get(x,x[:-1])
        m=LINE.match(line)
        if not m:continue
        raw=m['args']; terms=[s.strip() for s in raw.split(',')]
        try:vals=[parse_int(s) for s in terms]
        except ValueError:continue
        if not vals:continue
        group=None
        if m['width'].lower()=='w':
            if section=='points' and len(vals)==3:group='vertices'
            if section=='vectors' and len(vals)==3:group='normals'
            if section=='edges' and len(vals)==2:group='edges'
            if section=='dividers' and len(vals)==2:group='collision_dividers'
            n=vals[0]&15
            if section=='surfaces' and len(vals)==n+3 and 3<=n<=15 and ((vals[0]&0xF000) in (0x2000,0xA000)):
                group='surfaces'
        if group:
            rows.append(dict(line=lineno,group=group,values=vals))
    return rows

def faces_from_edges(edges, verts, surfaces):
    faces=[]; failures=[]
    for i,s in enumerate(surfaces):
        v=s['values']; n=v[0]&15
        ids=[w & 0x7fff for w in v[2:-1]]
        try: selected=[edges[j]['values'] for j in ids]
        except IndexError:
            failures.append((i,'bad edge reference'));continue
        cycle=None
        for flip in (False,True):
            a,b=selected[0]
            if flip:a,b=b,a
            loop=[a,b]
            for x,y in selected[1:]:
                if x==loop[-1]:loop.append(y)
                elif y==loop[-1]:loop.append(x)
                else:break
            if len(loop)==n+1 and loop[-1]==loop[0] and all(1<=pt<=len(verts) for pt in loop[:-1]):
                cycle=loop[:-1];break
        if cycle is None:failures.append((i,'edges do not form one cycle'));continue
        faces.append(dict(surface_index=i,vertices=cycle,flags=v[0]&0xfff0,normal=v[1],color=v[-1]))
    return faces,failures

def manifest_paths():
    # Avoid lowercase duplicate aliases on case-sensitive Linux filesystems.
    return [Path(x) for x in ['CAR1.MDL','CAR2.MDL','CAR3.MDL','CAR4.MDL','CAR5.MDL','CAR6.MDL',
                              'CARS/CAR2.MDL','CARS/CAR3.MDL','CARS/DRONE.MDL',
                              'CARS/CAR2.BND','CARS/CAR3.BND','CARS/DRONE.BND']]

def write_preview(d,rel):
    """Two orthographic PNG diagnostics, NOT texture authoring or game art."""
    vertices=[r['values'] for r in d['groups']['vertices']]
    edges=[r['values'] for r in d['groups']['edges']]
    if not vertices:return
    scale=2
    im=Image.new('RGB',(960*scale,520*scale),(244,245,247))
    dr=ImageDraw.Draw(im)
    projections=[(0,2,'TOP (X/Z)'),(2,1,'SIDE (Z/Y)')]
    for slot,(u,v,heading) in enumerate(projections):
        x0=slot*480*scale
        dr.text((x0+24*scale,22*scale),str(rel)+' - '+heading,fill=(35,42,53),stroke_width=0)
        coords=[(p[u],-p[v]) for p in vertices]
        lo_x=min(x for x,y in coords);hi_x=max(x for x,y in coords)
        lo_y=min(y for x,y in coords);hi_y=max(y for x,y in coords)
        span=max(hi_x-lo_x,hi_y-lo_y,1)
        factor=(405*scale)/span
        def tr(p):return (round(x0+240*scale+(p[0]-(hi_x+lo_x)/2)*factor),round(270*scale+(p[1]-(hi_y+lo_y)/2)*factor))
        for a,b in edges:
            if 1<=a<=len(coords) and 1<=b<=len(coords):
                dr.line([tr(coords[a-1]),tr(coords[b-1])],fill=(41,78,118),width=2*scale)
        dr.text((x0+20*scale,480*scale),f'{len(vertices)} points / {len(edges)} edges - Jaguar native geometry',fill=(60,68,78))
    path=BASE/'previews'/rel.with_suffix('.png');path.parent.mkdir(parents=True,exist_ok=True)
    im.resize((960,520),Image.Resampling.LANCZOS).save(path)

def authoring_file(rel):return BASE/'json'/rel.with_suffix(rel.suffix+'.json')
def template_file(rel):return BASE/'templates'/rel

def export(rel):
    source=asset_file(rel)
    tpl=template_file(rel);tpl.parent.mkdir(parents=True,exist_ok=True)
    data=source.read_bytes();tpl.write_bytes(data)
    text=data.decode('latin1');rows=scan(text, rel.suffix[1:])
    groups={k:[r for r in rows if r['group']==k] for k in ('vertices','normals','edges','surfaces','collision_dividers')}
    faces,problems=faces_from_edges(groups['edges'],groups['vertices'],groups['surfaces'])
    d={'schema':'club-native-model', 'original':str(rel),
       'template_sha256':hashlib.sha256(data).hexdigest(),
       'notes':['2026 reconstruction; native numeric values only; historical comments live in template',
                'Vertex indices in edge lists are 1-based; polygon edge IDs are 0-based, bit 15 encodes edge direction',
                'Leave counts unchanged: collision BSP trees, pointer offsets and bounding radius are NOT regenerated',
                'Faces/OBJ are derived previews; change surfaces[*].values and edges[*].values to edit actual model'],
       'groups':groups,
       'preview':{'faces':faces,'unresolved_polygon_cycles':problems}}
    dst=authoring_file(rel);dst.parent.mkdir(parents=True,exist_ok=True)
    dst.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
    write_obj(d,rel)
    write_preview(d,rel)
    return d

def write_obj(d,rel):
    verts=d['groups']['vertices'];edges=d['groups']['edges'];polys=d['groups']['surfaces']
    faces,failed=faces_from_edges(edges,verts,polys)
    path=BASE/'obj'/rel.with_suffix('.obj');path.parent.mkdir(parents=True,exist_ok=True)
    lines=['# Club Drive Jaguar native model: reconstructed 2026',
           '# Vertex coordinates are original signed 16-bit words',
           '# This is a visual OBJ export, not the Jaguar BSP/collision tree',
           'o '+str(rel).replace('/','_').replace('.','_')]
    for r in verts:lines.append('v '+' '.join(str(x) for x in r['values']))
    for f in faces:
        lines.append(f'# flags=0x{f["flags"]:04X}, original_vector={f["normal"]}, color_word={f["color"]}')
        lines.append('f '+' '.join(map(str,f['vertices'])))
    path.write_text('\n'.join(lines)+'\n')
    return len(faces),len(failed)

def compile_model(rel,check_only=False):
    doc=json.loads(authoring_file(rel).read_text());tpl=template_file(rel).read_bytes()
    if doc['schema']!='club-native-model' or doc['original']!=str(rel): raise ValueError(f'{rel}: wrong JSON schema/identity')
    if hashlib.sha256(tpl).hexdigest()!=doc['template_sha256']: raise ValueError(f'{rel}: template digest mismatch')
    original=tpl.decode('latin1');lines=original.splitlines(keepends=True)
    expected=scan(original,rel.suffix[1:]);given=[r for g in doc['groups'].values() for r in g]
    if {r['line'] for r in expected}!={r['line'] for r in given} or len(expected)!=len(given):
        raise ValueError(f'{rel}: native record count/identity changed; regenerate collision structures first')
    emap={r['line']:r for r in expected}; replacements=0
    for row in given:
        old=emap[row['line']]
        if row['group']!=old['group'] or len(row['values'])!=len(old['values']):raise ValueError(f'{rel}: structure at line {row["line"]} changed')
        vals=row['values']
        if any(not isinstance(v,int) for v in vals):raise ValueError(f'{rel}: all native values must be integers')
        line=lines[row['line']];m=LINE.match(line)
        width=16 if m['width'].lower()=='w' else 32
        if any(v < -(1<<(width-1)) or v >= 1<<width for v in vals):raise ValueError(f'{rel}: value does not fit {width} bits on line {row["line"]}')
        if vals==old['values']:continue
        terms=[q.strip() for q in m['args'].split(',')]
        # Preserve unchanged numeric spelling and original comments verbatim.
        # For edited values use signed decimal; both +/- and $hex are accepted by RMAC.
        for j,v in enumerate(vals):
            if v!=old['values'][j]:terms[j]=str(v)
        lead=m.group(1); comment=m.group('comment')
        ending='\r\n' if line.endswith('\r\n') else '\n' if line.endswith('\n') else ''
        lines[row['line']]=lead+', '.join(terms)+comment.rstrip('\r\n')+ending
        replacements+=1
    # Validate model references independently of source text.
    groups=doc['groups'];edges=groups['edges'];vertices=groups['vertices'];polygons=groups['surfaces']
    if any(not all(1<=v<=len(vertices) for v in edge['values']) for edge in edges):raise ValueError(f'{rel}: edge points outside vertex table')
    faces,bad=faces_from_edges(edges,vertices,polygons)
    if bad:raise ValueError(f'{rel}: non-closed polygons or bad edge references: {bad[:6]}')
    # 2026 reconstruction: overlay a validated symbolic BSP tree from JSON.
    # This preserves every original Atari comment and the original eight-byte
    # node layout; the split/leaf geometry is NOT regenerated automatically.
    from bsp_authoring import patch_assembled
    result=patch_assembled(rel, ''.join(lines).encode('latin1'))
    out=asset_file(rel)
    # The surviving play.s includes the lowercase aliases on Linux.
    # Keep the six runtime car-model aliases synchronized with authoring.
    alias=(asset_file(rel.name.lower())) if rel.parent==Path('.') and re.fullmatch(r'CAR[1-6]\.MDL',rel.name) else None
    if check_only:
        if out.read_bytes()!=result:raise ValueError(f'{rel}: generated model is stale, run compile')
        if alias and alias.read_bytes()!=result:raise ValueError(f'{rel}: runtime lowercase .mdl alias is stale')
    else:
        out.write_bytes(result)
        if alias: alias.write_bytes(result)
        write_obj(doc,rel)
        write_preview(doc,rel)
    return replacements,len(faces),len(vertices)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=('export','compile','check','stats'))
    p.add_argument('--file',help='Single model relative to project root; default all canonical models')
    p.add_argument('--overwrite-export',action='store_true',help='Replace existing JSON edits with current native source')
    a=p.parse_args()
    files=[Path(a.file)] if a.file else manifest_paths()
    if a.command=='export':
        for rel in files:
            if authoring_file(rel).exists() and not a.overwrite_export:raise ValueError(f'{rel}: JSON already exists; not overwriting edits')
            d=export(rel)
            print('EXPORT',rel,','.join(f'{k}={len(v)}' for k,v in d['groups'].items()))
    else:
        for rel in files:
            if a.command=='stats':
                d=json.loads(authoring_file(rel).read_text());counts={g:len(v) for g,v in d['groups'].items()}
                print(rel,counts,'faces',len(d['preview']['faces']))
            else:
                print(a.command.upper(),rel,compile_model(rel, a.command=='check'))
if __name__=='__main__':main()
