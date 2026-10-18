#!/usr/bin/env python3
"""Club Drive native_tree: relocatable Jaguar-native .MDL tree *authoring* writer.

2026 reconstruction, NOT original Atari mkbnd/findbg/bnd2mdl.

Source evidence: surviving .MDL files, BNDHEAD.INC, MODEL.DOC, tree.gas.
Native tree records are eight bytes. Interior node = dc.w 0,divider,
front_offset,back_offset. Leaf = dc.w 1,flags; dc.l cp_list_offset.
Links are signed 16-bit byte offsets from the tree base; -1 is an empty
branch (GPU tree.gas checks bit 15), NOT a leaf. Dividers are point/normal
indices into existing tables. This tool can add/remove/reorder nodes and
relocate later model data, but cannot yet manufacture valid new CP polygons,
normals or editable world collision behavior. The runtime model is never
replaced by these outputs automatically.
"""
import argparse
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

import bsp_authoring as old

ROOT = old.ROOT
BASE = ROOT / 'assets/bsp/trees'
CPRE = old.CPRE
NODERE = old.NODERE
WORDRE = old.WORDRE
HEADER_COUNT = re.compile(r'^\s*dc\.w\s+(\d+)\s*;\s*(NUM_PNTS|NUM_VECTORS|NUM_DIVIDERS|NUM_EDGES|NUM_CPS|NUM_COLORS)\s*$', re.I)
HEADER_PTR = re.compile(r'^(\s*dc\.l\s+)([A-Za-z_]\w*_data)\+(\d+)(\s*;\s*([^\r\n]+))(\r?\n?)$', re.I)


def native_layout(rel, blob=None):
    """Check CP boundaries, node/table offsets and header relocations."""
    original = old.original(rel) if blob is None else blob
    s = original.decode('latin1')
    lines = s.splitlines(keepends=True)
    nodes, cp_comments = old.read_nodes(s)
    node_lines = [i for i, line in enumerate(lines) if NODERE.match(line)]
    if len(node_lines) != len(nodes):
        raise ValueError('Native node label count mismatch')
    first = node_lines[0]
    last = node_lines[-1]
    while last + 1 < len(lines) and not re.match(r'^\s*;\s*colors\s*$', lines[last + 1].strip(), re.I):
        last += 1
    colors = next((i for i in range(node_lines[-1]+1, len(lines)) if re.match(r'^\s*;\s*colors\s*$', lines[i].strip(), re.I)), None)
    if colors is None:
        raise ValueError(f'{rel}: no post-tree colors marker')
    if any(NODERE.match(line) for line in lines[colors:]):
        raise ValueError('Node found beyond color table')
    align = next((i for i in range(first - 1, -1, -1) if lines[i].strip()), None)
    if align is None or lines[align].strip() != '.long':
        raise ValueError('Native tree must follow its .long alignment directive')
    cps = []
    current = None
    for i, line in enumerate(lines[:align]):
        marker = CPRE.match(line)
        if marker:
            if current is not None:
                cps.append(current)
            current = {'index':int(marker[1]), 'offset':int(marker[2]), 'words':[], 'line':i}
        elif current is not None:
            m = WORDRE.match(line)
            if m:
                current['words'].extend(old.get_int(v) for v in m[2].split(','))
    if current is not None:
        cps.append(current)
    if len(cps) != len(cp_comments) or not cps:
        raise ValueError('Missing or duplicated CP sections')
    if [x['index'] for x in cps] != list(range(cps[0]['index'], cps[0]['index'] + len(cps))):
        raise ValueError('Nonsequential CP indices')
    cum = 0
    polygon_total = 0
    for record in cps:
        if record['offset'] != cum:
            raise ValueError(f"CP {record['index']}: offset {record['offset']} != byte count {cum}")
        words = record['words']
        if not words or words[-1] != 0:
            raise ValueError(f"CP {record['index']}: missing zero terminator")
        pos = 0
        while pos < len(words)-1:
            sides = words[pos] & 15
            if not (3 <= sides <= 15):
                raise ValueError(f"CP {record['index']}: illegal sides at word {pos}")
            if len(words)-1-pos < sides+3:
                raise ValueError(f"CP {record['index']}: incomplete polygon")
            pos += sides+3
            polygon_total += 1
        if pos != len(words)-1:
            raise ValueError(f"CP {record['index']}: internal zero terminator / misaligned polygon")
        cum += 2*len(words)
    counts = {m[2].upper():int(m[1]) for line in lines if (m := HEADER_COUNT.match(line))}
    pointers = {}
    for i, line in enumerate(lines):
        m = HEADER_PTR.match(line)
        if m:
            pointers[m[5].strip().lower()] = {'line':i, 'number':int(m[3]), 'label':m[2]}
    required = ('dividers', 'edges', 'points', 'tris', 'end of tris', 'tree', 'calculated colors')
    if counts:
        if set(('NUM_PNTS','NUM_VECTORS','NUM_DIVIDERS','NUM_EDGES','NUM_CPS','NUM_COLORS')) - counts.keys():
            raise ValueError(f'{rel}: incomplete native header counts')
        if any(x not in pointers for x in required):
            raise ValueError(f'{rel}: missing native header pointers')
        p = {k:pointers[k]['number'] for k in required}
        expected = {'dividers':0,
                    'edges':4*counts['NUM_DIVIDERS'],
                    'points':4*(counts['NUM_DIVIDERS']+counts['NUM_EDGES'])}
        expected['tris'] = expected['points'] + 6*(counts['NUM_PNTS']+counts['NUM_VECTORS'])
        for k,v in expected.items():
            if p[k]!=v:
                raise ValueError(f'{rel}: {k} pointer {p[k]} != packed native offset {v}')
        if p['tree'] != ((p['tris']+cum+3)&~3) or p['tris']+cum-p['end of tris'] not in (0,2):
            raise ValueError(f'{rel}: CP serialized size / alignment disagrees with native tree')
        # CAR1/CAR6's historical SURFS_END address precedes the last CP
        # terminator by one word. Preserve this original anomaly verbatim.
        # .long aligns TREE to the next 4-byte boundary.
        if p['calculated colors'] != p['tree']+8*len(nodes):
            raise ValueError(f'{rel}: color table does not follow tree')
        if counts['NUM_CPS'] != len(cps):
            # The surviving CARS/DRONE.MDL has NUM_CPS=3 but only CP1 and
            # CP2 in its data section. Do not manufacture a missing CP0.
            if not (rel==Path('CARS/DRONE.MDL') and counts['NUM_CPS']==3
                    and [x['index'] for x in cps]==[1,2]):
                raise ValueError(f'{rel}: NUM_CPS mismatch')
    for node in nodes:
        if node['type']=='leaf' and node['cp_offset'] not in cp_comments:
            raise ValueError('Native tree leaf lacks CP boundary')
    return {'rel':str(rel),'source_sha256':hashlib.sha256(original).hexdigest(),
            'lines':lines,'first_node':first,'after_nodes':colors,'nodes':nodes,
            'cp_map':cp_comments,'cp_records':cps,'cp_bytes':cum,'polygons':polygon_total,
            'header_counts':counts,'header_pointers':pointers}


def path(rel):
    return BASE / 'json' / rel.with_suffix(rel.suffix + '.native_tree.json')


def output_path(rel):
    return BASE / 'generated' / rel


def export_doc(rel):
    layout = native_layout(rel)
    nodes = layout['nodes']
    def label(k):return f'n{k//8:04d}'
    serialized = []
    for n in nodes:
        d={'id':label(n['offset']), 'type':n['type']}
        if n['type']=='split':
            d.update(divider=n['divider'],first=label(n['first_child']),second=label(n['second_child']))
        else:
            d.update(flags=n['unused_word'],cp_offset=n['cp_offset'])
        serialized.append(d)
    return {'schema':'club-native-tree','source_model':str(rel),
            'source_template_sha256':layout['source_sha256'],
            'provenance':'Reconstructed in 2026 from Atari .MDL records and GPU tree.gas, not mkbnd',
            'safety':'Generated .MDL files are separate; clean ROM keeps original tree',
            'nodes':serialized}


def validate_doc(rel, doc, layout=None):
    layout = layout or native_layout(rel)
    if doc.get('schema') != 'club-native-tree' or doc.get('source_model') != str(rel) or doc.get('source_template_sha256') != layout['source_sha256']:
        raise ValueError('Native topology template identity mismatch')
    nodes = doc.get('nodes')
    if not isinstance(nodes,list) or not nodes or len(nodes)>=4096:
        raise ValueError('Native topology must contain 1..4095 nodes (signed 16-bit child offset)')
    ids=[n.get('id') for n in nodes]
    if any(not isinstance(k,str) or not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]{0,63}',k) for k in ids) or len(ids)!=len(set(ids)):
        raise ValueError('Duplicate or invalid native node ID')
    by={n['id']:n for n in nodes}
    cp=layout['cp_map']
    ndiv=layout['header_counts'].get('NUM_DIVIDERS',old.divider_count(old.original(rel).decode('latin1')) if 'NUM_DIVIDERS' in old.original(rel).decode('latin1') else -1)
    # The stand-alone DRONE data section has no bndheader. Its source native
    # divider table spans from drone_data to the ; edges marker; count it.
    if ndiv<0:
        text=old.original(rel).decode('latin1')
        rows=text.split('; edges')[0].splitlines()
        ndiv=sum(bool(WORDRE.match(line)) and len(WORDRE.match(line)[2].split(','))==2 for line in rows)
    seen=set();leaf_offsets=[];splits=0;empty=0
    def visit(key,trail):
        nonlocal splits,empty
        if key is None:
            empty+=1;return
        if key not in by:raise ValueError(f'Unknown native child {key}')
        if key in trail:raise ValueError(f'Native tree cycle at {key}')
        if key in seen:raise ValueError(f'Native tree multiple parents at {key}')
        seen.add(key)
        n=by[key]
        if n.get('type')=='split':
            splits+=1
            div=n.get('divider')
            if type(div)!=int or not (div==-1 or 0<=div<ndiv):
                raise ValueError(f'{key}: invalid divider index {div}')
            if n.get('first') is None and n.get('second') is None:
                raise ValueError(f'{key}: split cannot have two empty children')
            visit(n.get('first'),trail|{key})
            visit(n.get('second'),trail|{key})
        elif n.get('type')=='leaf':
            if n.get('flags')!=0:
                raise ValueError(f'{key}: unknown native leaf flags; only existing zero flags are understood')
            p=n.get('cp_offset')
            if type(p)!=int or p not in cp or cp[p]==0:
                raise ValueError(f'{key}: unknown/background CP offset')
            leaf_offsets.append(p)
        else:raise ValueError(f'{key}: invalid node type')
    visit(ids[0],set())
    if len(seen)!=len(nodes):raise ValueError('Unreachable native tree nodes')
    expected={offset for offset,i in cp.items() if i!=0}
    if Counter(leaf_offsets)!=Counter(expected):
        raise ValueError('Native leaves must cover each existing non-background CP exactly once')
    if splits+len(leaf_offsets)!=len(nodes) or splits+1 != len(leaf_offsets)+empty:
        raise ValueError('Native child count/full binary invariant violated')
    return {'nodes':len(nodes),'splits':splits,'leaves':len(leaf_offsets),
            'empty_children':empty,'cp_bytes':layout['cp_bytes'],
            'cp_polygons':layout['polygons'],'original_nodes':len(layout['nodes'])}


def compiled_records(doc):
    nodes=doc['nodes']
    where={n['id']:i*8 for i,n in enumerate(nodes)}
    records=[]
    for n in nodes:
        if n['type']=='split':
            first=-1 if n.get('first') is None else where[n['first']]
            second=-1 if n.get('second') is None else where[n['second']]
            records.append(('split',n['divider'],first,second))
        else:records.append(('leaf',n['flags'],n['cp_offset']))
    return records


def original_records(layout):
    return [(('split',n['divider'],n['first_child'],n['second_child']) if n['type']=='split'
             else ('leaf',n['unused_word'],n['cp_offset'])) for n in layout['nodes']]


def compile_text(rel,doc):
    layout=native_layout(rel)
    stats=validate_doc(rel,doc,layout)
    records=compiled_records(doc)
    if records==original_records(layout):
        return old.original(rel),stats
    lines=layout['lines']
    replacement=[]
    for i,r in enumerate(records):
        replacement.append(f'\t\t\t; Node {i*8}\n')
        if r[0]=='split':replacement.append(f'\tdc.w\t0, {r[1]}, {r[2]}, {r[3]}\n')
        else:
            replacement.append(f'\tdc.w\t1, {r[1]}\n')
            replacement.append(f'\tdc.l\t{r[2]}\n')
    # Never modify the original arrays/CP lists. Rebase the header's pointers
    # into data *after* the serialized tree; currently the color table is the
    # only such reference in the nine documented inputs.
    delta=8*(len(records)-len(layout['nodes']))
    mutated=list(lines)
    if delta:
        pointers=layout['header_pointers']
        if pointers:
            entry=pointers['calculated colors']
            idx=entry['line'];m=HEADER_PTR.match(lines[idx])
            if not m:raise ValueError('Cannot safely rewrite color-list relocation')
            if any(k!='calculated colors' and v['number']>=entry['number'] for k,v in pointers.items()):
                raise ValueError('Unknown header data pointer after the native tree')
            mutated[idx]=m[1]+m[2]+'+'+str(entry['number']+delta)+m[4]+m[6]
    result=''.join(mutated[:layout['first_node']]+replacement+mutated[layout['after_nodes']:]).encode('latin1')
    # Complete the essential native assembly syntax and relocations check:
    # a second parser verifies our output has the intended eight-byte records.
    parsed,_=old.read_nodes(result.decode('latin1'))
    if len(parsed)!=len(records):raise ValueError('Native output loses tree records')
    if [x for x in [('split',n['divider'],n['first_child'],n['second_child']) if n['type']=='split' else ('leaf',n['unused_word'],n['cp_offset']) for n in parsed]]!=records:
        raise ValueError('Compiled tree differs from serialized node table')
    # Independent second pass: check CP terminators, all pointer arithmetic
    # and aligned node offsets on the *new* source, not just the original.
    second=native_layout(rel,result)
    if len(second['nodes'])!=len(records):raise ValueError('New native layout invalid')
    return result,stats


def emit(rel,check=False):
    doc=json.loads(path(rel).read_text())
    raw,stats=compile_text(rel,doc)
    outfile=output_path(rel)
    if check:
        if not outfile.exists() or outfile.read_bytes()!=raw:raise ValueError(f'{rel}: compiled .MDL is stale')
    else:
        outfile.parent.mkdir(parents=True,exist_ok=True)
        outfile.write_bytes(raw)
    print(('CHECK' if check else 'COMPILE'),str(rel),stats)
    return stats


def build_probe():
    """Add a redundant split and an empty child to CAR2, without touching game data.

    Source-based proof of branch semantics: GPU tree.gas tests bit 15 on a
    signed child offset and returns for negative offsets. This is a structural
    test case, NOT a gameplay/physics parity assertion.
    """
    rel=Path('CAR2.MDL')
    d=export_doc(rel)
    root=d['nodes'][0]
    old_second=root['second']
    root['second']='extra_split'
    d['nodes'].append({'id':'extra_split','type':'split','divider':-1,
                       'first':None,'second':old_second})
    # Relocating the native color pointer is the crucial difference from bsp.
    raw,stats=compile_text(rel,d)
    outfile=BASE/'probes'/'CAR2_redundant_split.MDL'
    outfile.parent.mkdir(parents=True,exist_ok=True)
    outfile.write_bytes(raw)
    (outfile.parent/'CAR2_redundant_split.json').write_text(json.dumps(d,indent=2)+'\n')
    return stats


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=('export','compile','check','probe','audit'))
    parser.add_argument('--only',action='append', help='Model path, e.g. CAR2.MDL')
    a=parser.parse_args()
    if a.action=='probe':
        print('PROBE', build_probe());return
    files=[Path(n) for n in a.only] if a.only else old.MODEL_FILES
    result={}
    for rel in files:
        if rel not in old.MODEL_FILES:raise ValueError('Model is not part of the verified original native set')
        if a.action=='export':
            p=path(rel);p.parent.mkdir(parents=True,exist_ok=True)
            if p.exists():raise ValueError(f'{p}: refusing to overwrite authored edits')
            p.write_text(json.dumps(export_doc(rel),indent=2)+'\n')
            result[str(rel)]='exported'
        elif a.action=='audit':
            v=native_layout(rel)
            result[str(rel)]={'cp_bytes':v['cp_bytes'],'polygons':v['polygons'],
                              'cp_lists':len(v['cp_records']),'nodes':len(v['nodes']),
                              'header_verified':bool(v['header_counts'])}
        else:result[str(rel)]=emit(rel,a.action=='check')
    if not a.only and a.action in ('compile','audit'):
        (BASE/'native_layout_index.json').write_text(json.dumps(result,indent=2)+'\n')
    print('TOTAL',a.action,len(result),'models')

if __name__=='__main__':main()
