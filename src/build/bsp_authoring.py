#!/usr/bin/env python3
"""Club Drive .MDL BSP-tree authoring (2026 reconstruction, NOT Atari code).

Source evidence: surviving CARS/*.MDL, CAR1..CAR6.MDL, BNDHEAD.INC,
MODEL.DOC. A tree node occupies 8 bytes: type=0, divider, two byte offsets;
or type=1, unused word, one long CP-list offset. A divider value of -1
is preserved as a special sentinel found in the original CAR1/CAR6 trees.
Internal child offsets are
relative to the start of the tree, and leaf CP-list offsets to the tris list.

This tool reconstructs, validates, serializes and visualizes that *existing*
topology, not the unavailable original mkbnd spatial-partition algorithm.
Only same-size/same-node-type edits are accepted. The original Atari
comments, assembler labels, alignment, and unmodified number spellings survive.
Invalid children, cycles, missing leaves, and unknown CP targets fail closed.
"""
import argparse, hashlib, json, re, sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent.parent
BASE=ROOT/'assets/bsp/native'
NODERE=re.compile(r'^\s*;\s*Node\s+(\d+)\s*$',re.I)
CPRE=re.compile(r'^\s*;\s*cpnode\s+#(\d+)\s+offset\s+(\d+)\s*$',re.I)
WORDRE=re.compile(r'^(\s*dc\.w\s+)([^;\r\n]+)(;[^\r\n]*)?(\r?\n?)$',re.I)
LONGRE=re.compile(r'^(\s*dc\.l\s+)([^;\r\n]+)(;[^\r\n]*)?(\r?\n?)$',re.I)
MODEL_FILES=[Path(f'CAR{x}.MDL') for x in range(1,7)]+[Path(f'CARS/{f}.MDL') for f in ('CAR2','CAR3','DRONE')]

def get_int(token):
    token=token.strip();sign=-1 if token.startswith('-') else 1
    token=token.lstrip('+-')
    return sign*int(token[1:],16) if token.startswith('$') else sign*int(token,0) if token.lower().startswith('0x') else sign*int(token,10)

def read_nodes(src):
    lines=src.splitlines(keepends=True); nodes=[]; cp={}
    for i,line in enumerate(lines):
        m=CPRE.match(line)
        if m: cp[int(m[2])]=int(m[1])
        m=NODERE.match(line)
        if not m: continue
        offset=int(m[1]);j=i+1
        while j<len(lines) and not lines[j].strip():j+=1
        word=WORDRE.match(lines[j]) if j<len(lines) else None
        if not word:raise ValueError(f'Node {offset}: missing dc.w at line {i+1}')
        nums=[get_int(v) for v in word[2].split(',')]
        if len(nums)==4 and nums[0]==0:
            n={'offset':offset,'type':'split','divider':nums[1], 'first_child':nums[2], 'second_child':nums[3], 'line':j}
        elif len(nums)==2 and nums[0]==1:
            k=j+1
            while k<len(lines) and not lines[k].strip():k+=1
            lng=LONGRE.match(lines[k]) if k<len(lines) else None
            if not lng:raise ValueError(f'Node {offset}: expected dc.l after leaf')
            n={'offset':offset,'type':'leaf','unused_word':nums[1], 'cp_offset':get_int(lng[2]), 'line':j, 'long_line':k}
        else:raise ValueError(f'Node {offset}: unexpected type/word layout {nums}')
        nodes.append(n)
    if not nodes:raise ValueError('Missing semantically labeled ; Node records')
    return nodes,cp

def divider_count(src):
    h=re.search(r'^\s*dc\.w\s+\d+\s*;\s*NUM_DIVIDERS\s*$',src,re.M|re.I)
    if not h:raise ValueError('NUM_DIVIDERS header missing')
    return int(h.group().split('dc.w')[1].split(';')[0].strip())

def validate(nodes,cp,div_count):
    by={n['offset']:n for n in nodes}
    if len(by)!=len(nodes) or set(by)!={i*8 for i in range(len(nodes))}:
        raise ValueError('Tree node addresses are not exactly contiguous 8-byte records')
    seen=set();leaves=[];split_count=0
    def visit(k,chain):
        nonlocal split_count
        if k in chain:raise ValueError(f'BSP cycle at offset {k}')
        if k not in by:raise ValueError(f'Bad BSP child offset {k}')
        if k in seen:raise ValueError(f'BSP node {k} has multiple parents')
        seen.add(k);n=by[k]
        if n['type']=='split':
            split_count+=1
            if not isinstance(n['divider'],int) or isinstance(n['divider'],bool) or not (n['divider']==-1 or 0<=n['divider']<div_count):
                raise ValueError(f'Node {k}: invalid collision-divider index {n["divider"]}')
            for field in ('first_child','second_child'):
                target=n[field]
                if not isinstance(target,int) or isinstance(target,bool) or target==k or target%8:raise ValueError(f'Node {k}: bad child {field}={target}')
                visit(target,chain|{k})
        elif n['type']=='leaf':
            if n['unused_word']!=0 or n['cp_offset'] not in cp:raise ValueError(f'Node {k}: invalid leaf CP offset {n["cp_offset"]}')
            leaves.append(n['cp_offset'])
        else:raise ValueError(f'Node {k}: unknown type')
    visit(0,set())
    if seen!=set(by):raise ValueError(f'Unreachable BSP nodes: {sorted(set(by)-seen)}')
    if split_count+len(leaves)!=len(nodes) or len(leaves)!=split_count+1:raise ValueError('Invalid full-binary BSP')
    # CP0 is the historical empty/background list, not assigned to a leaf.
    expected={off for off,idx in cp.items() if idx!=0}
    if len(leaves)!=len(set(leaves)) or set(leaves)!=expected:
        raise ValueError('BSP leaves must cover each non-background collision polygon list exactly once')
    return {'nodes':len(nodes),'splits':split_count,'leaves':len(leaves),'cp_indices':[cp[v] for v in leaves]}

def jpath(rel):return BASE/'json'/rel.with_suffix(rel.suffix+'.bsp.json')
def original(rel):return (ROOT/'assets/3d/native_models'/'templates'/rel).read_bytes()

def export(rel):
    raw=original(rel);src=raw.decode('latin1');nodes,cp=read_nodes(src)
    stats=validate(nodes,cp,divider_count(src))
    doc={'schema':'club-bsp','source_model':str(rel),'source_template_sha256':hashlib.sha256(raw).hexdigest(),
         'provenance':'2026 symbolic reconstruction from surviving original .MDL tree comments and header',
         'limitations':['BSP splitter selection and polygon repartitioning are NOT derived from 3D geometry',
                        'Only existing node types and record sizes are editable',
                        'Leaves reference offsets of existing collision polygon lists, not vertex IDs'],
         'valid_cp_offsets':dict((str(off),i) for off,i in sorted(cp.items())),
         'divider_count':divider_count(src),'nodes':nodes,'statistics':stats}
    p=jpath(rel);p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(doc,indent=2)+'\n')
    render(rel,doc)
    return stats

def compile_text(rel, doc):
    template=original(rel);src=template.decode('latin1')
    if doc.get('schema')!='club-bsp' or doc.get('source_model')!=str(rel) or doc.get('source_template_sha256')!=hashlib.sha256(template).hexdigest():
        raise ValueError(f'{rel}: template identity mismatch')
    base,cp=read_nodes(src)
    wanted=doc.get('nodes')
    if len(wanted)!=len(base):raise ValueError('Node count changed; native header offsets require full regeneration')
    if doc.get('divider_count')!=divider_count(src):raise ValueError('Divider count mismatch')
    for b,n in zip(base,wanted):
        if b['offset']!=n.get('offset') or b['type']!=n.get('type') or b['line']!=n.get('line') or (b.get('long_line')!=n.get('long_line')):
            raise ValueError(f'{rel}: changed BSP tree shape/line identity')
    # -1 is a historical special divider sentinel only in two confirmed
    # positions of CAR1 and CAR6; never introduce a new undocumented sentinel.
    for orig,new in zip(base,wanted):
        if new['type']=='split' and new['divider']==-1 and orig['divider']!=-1:
            raise ValueError('Cannot introduce new undocumented -1 divider sentinel')
    stats=validate(wanted,cp,divider_count(src))
    lines=src.splitlines(keepends=True)
    for b,n in zip(base,wanted):
        keys=('divider','first_child','second_child') if n['type']=='split' else ('unused_word','cp_offset')
        if any(n[k]!=b[k] for k in keys):
            keys_w=keys if n['type']=='split' else ('unused_word',)
            m=WORDRE.match(lines[b['line']]);terms=[s.strip() for s in m[2].split(',')]
            for i,k in enumerate(keys_w,1):
                if n[k]!=b[k]:terms[i]=str(n[k])
            lines[b['line']]=m[1]+', '.join(terms)+(m[3] or '')+(m[4] or '')
            if n['type']=='leaf' and n['cp_offset']!=b['cp_offset']:
                m=LONGRE.match(lines[b['long_line']]);lines[b['long_line']]=m[1]+str(n['cp_offset'])+(m[3] or '')+(m[4] or '')
    return ''.join(lines).encode('latin1'),stats

def patch_assembled(rel, raw):
    """Called by native_model_pipeline after it regenerates numeric records.

    The BSP JSON and old .MDL template are compared before any tree edits;
    replacing only recognized node operands preserves any edited vertices.
    """
    p=jpath(rel)
    if not p.exists():return raw
    doc=json.loads(p.read_text());base=original(rel).decode('latin1')
    result,_=compile_text(rel,doc)
    a=base.splitlines(keepends=True);b=result.decode('latin1').splitlines(keepends=True)
    c=raw.decode('latin1').splitlines(keepends=True)
    if len(a)!=len(b) or len(a)!=len(c):raise ValueError('Model size/line count changed; BSP overlay cannot be placed safely')
    for i,(x,y) in enumerate(zip(a,b)):
        if x!=y:
            if c[i]!=x:raise ValueError(f'Concurrent BSP edit conflict at line {i+1}')
            c[i]=y
    return ''.join(c).encode('latin1')

def render(rel,doc):
    nodes={n['offset']:n for n in doc['nodes']}; coords={}; level={};layers={}
    def visit(pos,d):
        n=nodes[pos]
        if n['type']=='split':
            a=visit(n['first_child'],d+1);b=visit(n['second_child'],d+1)
            x=(a+b)/2
        else:
            x=len(layers.setdefault('leaves',[]));layers['leaves'].append(pos)
        coords[pos]=(x,d);return x
    visit(0,0)
    maxdepth=max(y for x,y in coords.values());leaves=len(layers['leaves'])
    width=max(820,leaves*138+60);height=max(250,(maxdepth+1)*130+85)
    im=Image.new('RGB',(width,height),'#f7f8fa');d=ImageDraw.Draw(im)
    def xy(pos):
        x,y=coords[pos];return (round(45+(width-90)*(x+.5)/leaves),round(76+y*130))
    for pos,n in nodes.items():
        if n['type']=='split':
            for k in ('first_child','second_child'):
                d.line((xy(pos),xy(n[k])),fill='#9daec3',width=3)
    for pos,n in nodes.items():
        x,y=xy(pos);fill='#284667' if n['type']=='split' else '#59695b'
        d.rounded_rectangle((x-55,y-24,x+55,y+24),radius=9,fill=fill)
        label=f'div {n["divider"]}' if n['type']=='split' else f'CP {doc["valid_cp_offsets"][str(n["cp_offset"])]}'
        d.text((x-46,y-10),label,fill='white')
    d.text((20,18),f'{rel}  |  Recovered Jaguar BSP  |  2026 reconstruction',fill='#1d2a37')
    d.text((20,height-25),'PNG inspection view; BSP topology is maintained in JSON and generated .MDL assembly',fill='#4f5c68')
    path=BASE/'previews'/rel.with_suffix('.bsp.png');path.parent.mkdir(parents=True,exist_ok=True);im.save(path)

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('action',choices=('export','compile','check','stats'))
    a=parser.parse_args()
    result={}
    for rel in MODEL_FILES:
        if a.action=='export':stats=export(rel)
        else:
            doc=json.loads(jpath(rel).read_text());raw,stats=compile_text(rel,doc)
            if a.action in ('compile','check'):
                # Native compiler overlays validated BSP JSON after rewriting
                # editable vertices; it also keeps the lowercase runtime file.
                import native_model_pipeline as mdl
                mdl.compile_model(rel,check_only=(a.action=='check'))
            if a.action!='check':render(rel,doc)
        result[str(rel)]=stats
    (BASE/'bsp_index.json').write_text(json.dumps(result,indent=2)+'\n')
    for rel,stat in result.items():print(a.action.upper(),rel,stat)
if __name__=='__main__':main()
