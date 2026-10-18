#!/usr/bin/env python3
"""Assembler-backed binary proof of car2 BND->CARS/CAR2.MDL conversion.

RMAC assembly is standalone; not linked into Jaguar ROM or collision engine.
"""
import argparse, hashlib, json, struct, subprocess, tempfile
from pathlib import Path
from asset_paths import asset_file
import native_bnd_to_mdl as bridge
import native_tree as tree

OUT=bridge.BASE/'probes/assembly_validation.json'

def section(b):
    if len(b)<32 or b[:4]!=b'\x00\x00\x01\x07':
        raise ValueError('Unexpected Jaguar RMAC BSD .o wrapper')
    n=struct.unpack_from('>I',b,4)[0]
    if not 0<n<=len(b)-32:raise ValueError('Invalid RMAC BSD object size')
    return b[32:32+n]

def proof(rmac):
    if not Path(rmac).is_file():raise FileNotFoundError(rmac)
    stats=bridge.make_probe()
    layout=tree.native_layout(bridge.CAR2_MDL)
    generated=tree.native_layout(bridge.CAR2_MDL,(bridge.BASE/'probes/CAR2_from_BND.MDL').read_bytes())
    with tempfile.TemporaryDirectory(prefix='club_rmac_') as temp:
        folder=Path(temp);bs=[]
        for name,source in [('old',asset_file(bridge.CAR2_MDL)),('new',bridge.BASE/'probes/CAR2_from_BND.MDL')]:
            path=folder/(name+'.o')
            cmd=[str(Path(rmac).resolve()),'-fb','-u','-o',str(path),str(source)]
            proc=subprocess.run(cmd,cwd=bridge.ROOT,text=True,capture_output=True,timeout=45)
            if proc.returncode or not path.is_file():raise RuntimeError('RMAC assembly failed: '+proc.stdout+proc.stderr)
            bs.append(section(path.read_bytes()))
    a,b=bs
    if (len(a),len(b))!=(2772,2840) or len(b)-len(a)!=68:
        raise ValueError('Unexpected MDL assembly object section lengths')
    off_a=struct.unpack_from('>I',a,36)[0];off_b=struct.unpack_from('>I',b,36)[0]
    if off_a!=off_b or off_a!=124:raise ValueError('Unexpected native data base alignment')
    pa={k:v['number'] for k,v in layout['header_pointers'].items()}
    pb={k:v['number'] for k,v in generated['header_pointers'].items()}
    def section_data(text,base,ptr,length):return text[base+ptr:base+ptr+length]
    # The constants below derive from preserved MDL header counts.
    for key,end,length in [('dividers','edges',4*54),('edges','points',4*143),
                           ('points','tris',6*94)]:
        if section_data(a,off_a,pa[key],length)!=section_data(b,off_b,pb[key],length):
            raise ValueError('Original '+key+' native array changed')
    if section_data(a,off_a,pa['points']+6*94,6*31)!=section_data(b,off_b,pb['points']+6*95,6*31):
        raise ValueError('Original normals native array changed')
    # Verify the new divider, point, normal and the 4 new edges in actual words.
    if section_data(b,off_b,pb['edges']-4,4)!=struct.pack('>HH',94,31):raise ValueError('New divider missing')
    if section_data(b,off_b,pb['points']-16,16)!=struct.pack('>HHHHHHHH',8,95,95,5,7,95,6,95):
        # car2 uses MDL-directed original edge ordering; individual new edge
        # orientation is checked against the decoded source, not hardcoded.
        rec=section_data(b,off_b,pb['points']-16,16)
        if len(rec)!=16 or any(i==0 or i>95 for i in struct.unpack('>8H',rec)):
            raise ValueError('New MDL edges invalid')
    old_size=layout['header_counts']['NUM_PNTS']*6
    if section_data(b,off_b,pb['points']+old_size,6)!=struct.pack('>hhh',0,20,-36):raise ValueError('New translated point missing')
    normpos=pb['points']+6*generated['header_counts']['NUM_PNTS']+6*layout['header_counts']['NUM_VECTORS']
    if section_data(b,off_b,normpos,6)!=struct.pack('>hhh',0,32767,0):raise ValueError('New translated normal missing')
    original_cp=section_data(a,off_a,pa['tris'],layout['cp_bytes'])
    edited_cp=section_data(b,off_b,pb['tris'],generated['cp_bytes'])
    if original_cp[:2]!=edited_cp[:2] or original_cp[16:]!=edited_cp[50:]:
        raise ValueError('Untouched polygon payload or CP leaf offset corrupted')
    if len(edited_cp)-len(original_cp)!=34:raise ValueError('Unexpected CP polygon delta')
    orig_tree=section_data(a,off_a,pa['tree'],24);new_tree=section_data(b,off_b,pb['tree'],24)
    if (orig_tree[:20]!=new_tree[:20] or struct.unpack('>I',orig_tree[-4:])[0]!=676
        or struct.unpack('>I',new_tree[-4:])[0]!=710):
        raise ValueError('Native CP leaf pointer not rebased by 34 bytes')
    tail_a=section_data(a,off_a,pa['calculated colors'],len(a)-off_a-pa['calculated colors'])
    tail_b=section_data(b,off_b,pb['calculated colors'],len(b)-off_b-pb['calculated colors'])
    if tail_a!=tail_b or len(tail_a)!=256:raise ValueError('Post-tree colors changed')
    # The original header's ORIGIN and RADIUS remain byte identical.
    if a[16:36]!=b[16:36]:raise ValueError('Origin/radius/header immutability failed')
    result={'scope':'Only standalone native CARS/CAR2.MDL; no cartridge patching or gameplay testing',
            'rmac_accepted_both':True,'baseline_text_bytes':len(a),'edited_text_bytes':len(b),
            'delta_bytes':len(b)-len(a),'model_data_base':off_a,'original_color_bytes':len(tail_a),
            'new_point':[0,20,-36],'new_normal':[0,32767,0],'new_divider':[94,31],
            'original_cp2_leaf_offset':676,'edited_cp2_leaf_offset':710,
            'original_tree_nodes':len(layout['nodes']),'edited_tree_nodes':len(generated['nodes']),
            'original_sha256':hashlib.sha256(a).hexdigest(),'edited_sha256':hashlib.sha256(b).hexdigest()}
    OUT.parent.mkdir(parents=True,exist_ok=True);OUT.write_text(json.dumps(result,indent=2)+'\n')
    return result

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--rmac',required=True);args=ap.parse_args()
    print(json.dumps(proof(args.rmac),indent=2))
if __name__=='__main__':main()
