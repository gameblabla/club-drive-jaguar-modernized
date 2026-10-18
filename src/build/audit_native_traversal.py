#!/usr/bin/env python3
"""car3 source-grounded inventory of the Jaguar GPU's DRAW TREE path.

This is a draw-order tree. It does not classify solid/empty collision volumes.
"""
import argparse
import hashlib
import json
from pathlib import Path
import bsp_authoring as bsp
import native_tree as native

BASE=bsp.ROOT/'assets/3d/conversion/car3'
OUTPUT=BASE/'draw_tree_inventory.json'
from asset_paths import asset_file
SOURCE=asset_file('tree.gas')

# Exact GPU instructions confirmed against original source; a guard against
# silently promoting our interpretations if this evidence changes.
EVIDENCE={
    'root_address':'movei\t#TREE, cpTree',
    'signed_empty_branch':'btst\t#15,temp',
    'native_node_type':'loadw\t(cpNode),nodetype',
    'divider_sentinel':'btst\t#15,divnum',
    'camera_sign':'loadb\t(temp2),temp',
    'reverse_first_second':'move\tcpFront,cpBack',
    'back_called_first':'JSR_TREE\t\t\t; draw the back subtree',
    'front_tail_call':'jump\t(temp2)\t\t\t; draw the front subtree',
    'cp_leaf':'JSR_TREE\t\t\t\t; actually draw the CP',
}

def inspect():
    text=SOURCE.read_text('latin1')
    for name,needle in EVIDENCE.items():
        if needle not in text:raise ValueError('GPU draw-tree source evidence lost: '+name)
    models=[]
    for rel in bsp.MODEL_FILES:
        layout=native.native_layout(rel)
        offset_to_cp={r['offset']:r['index'] for r in layout['cp_records']}
        observed=[]
        root=layout['nodes'][0]
        nodes={n['offset']:n for n in layout['nodes']}
        seen=set()
        def visit(offset):
            if offset<0:return
            if offset in seen or offset not in nodes:
                raise ValueError('Unreachable/duplicate native draw-tree node')
            seen.add(offset)
            n=nodes[offset]
            if n['type']=='leaf':
                observed.append(offset_to_cp[n['cp_offset']]);return
            visit(n['first_child'])
            visit(n['second_child'])
        visit(root['offset'])
        if len(seen)!=len(nodes):raise ValueError('Unvisited native render tree node')
        models.append({'model':str(rel),'nodes':len(nodes),'split_nodes':sum(n['type']=='split' for n in layout['nodes']),
            'leaves':len(observed),'leaf_cp_indices':observed,
            'negative_child_sentinels':sum(n[k]<0 for n in layout['nodes'] if n['type']=='split' for k in ('first_child','second_child')),
            'negative_divider_sentinels':sum(n['divider']<0 for n in layout['nodes'] if n['type']=='split'),
            'source_tree_sha256':layout['source_sha256']})
    return {'schema':'club-native-gpu-draw-tree-audit',
            'gpu_source':'tree.gas','gpu_source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
            'semantics':{
                'node_offsets':'Eight-byte records; child offsets are relative to tree base',
                'negative_child':'Bit 15 set in child offset means return without drawing that branch',
                'split_divider_minus_one':'Skip camera-facing divider-sign swap',
                'positive_divider':'Read camera-transformed divider sign byte and conditionally swap front/back',
                'traversal':'Draw back first, then front, with camera-dependent order for non-sentinel split planes',
                'leaf':'Draw the CP polygon-list offset supplied by leaf record',
                'solid_empty_collision':'Not demonstrated by tree.gas; no volume ownership inferred'},
            'models':models}

def main():
    p=argparse.ArgumentParser();p.add_argument('action',choices=['compile','check']);args=p.parse_args()
    data=inspect()
    if args.action=='compile':
        BASE.mkdir(exist_ok=True,parents=True);OUTPUT.write_text(json.dumps(data,indent=2)+'\n')
    elif json.loads(OUTPUT.read_text())!=data:
        raise ValueError('Native drawing-tree audit is stale')
    print('Verified GPU draw-tree evidence for',len(data['models']),'surviving MDL models')
    print('Total nodes',sum(x['nodes'] for x in data['models']),
          'leaves',sum(x['leaves'] for x in data['models']))

if __name__=='__main__':main()
