#!/usr/bin/env python3
"""Assemble the native_tree topology-growth probe with the supplied Jaguar RMAC.

This is an exact binary layout verification of an *unlinked* model object,
not a gameplay or modified-ROM validation. It makes no changes to the game.
"""
import argparse
import hashlib
import json
import struct
import subprocess
import tempfile
from pathlib import Path
import native_tree as native

OUT = native.BASE/'probes'/'assembly_validation.json'

def check(rmac):
    model=Path('CAR2.MDL')
    native.build_probe()
    original=native.output_path(model)
    probe=native.BASE/'probes'/'CAR2_redundant_split.MDL'
    if original.read_bytes()!=native.old.original(model):
        raise ValueError('Clean original .MDL is not byte-identical')
    with tempfile.TemporaryDirectory(prefix='club_native_') as t:
        original_bin=Path(t)/'original.bin'
        probe_bin=Path(t)/'probe.bin'
        for path,out in ((original,original_bin),(probe,probe_bin)):
            cmd=[str(rmac),'-fb','-u','-o',str(out),str(path)]
            p=subprocess.run(cmd,cwd=native.ROOT,text=True,capture_output=True,timeout=30)
            if p.returncode or not out.is_file():
                raise RuntimeError(f'RMAC failed on {path}: exit={p.returncode}, {p.stdout} {p.stderr}')
        before=original_bin.read_bytes()
        after=probe_bin.read_bytes()
    root_before=struct.pack('>HHHH',0,13,16,8)
    root_after=struct.pack('>HHHH',0,13,16,24)
    offset=before.find(root_before)
    if offset<0 or after.find(root_after)!=offset:
        raise ValueError('RMAC native root record differs from expected Jaguar big-endian layout')
    if len(after)-len(before)!=8:
        raise ValueError('Native topology growth did not insert exactly one 8-byte node')
    # Original tree is 24 bytes, while probe tree is 32. Entire following
    # color data must remain byte-for-byte identical at its relocated address.
    if before[offset+24:] != after[offset+32:]:
        raise ValueError('Non-tree payload changed during native topology growth')
    oldtree=before[offset:offset+24]
    newtree=after[offset:offset+32]
    expected_old=root_before+struct.pack('>HHI',1,0,2)+struct.pack('>HHI',1,0,676)
    expected_new=root_after+struct.pack('>HHI',1,0,2)+struct.pack('>HHI',1,0,676)+struct.pack('>HHHH',0,0xffff,0xffff,8)
    if oldtree!=expected_old or newtree!=expected_new:
        raise ValueError('Native split, leaf or negative-empty-link serialization mismatch')
    # Source assembler relocates the generated color table pointer and one
    # alignment/end address by eight bytes. Nothing else outside tree moves.
    patches=[]
    for i in range(0,offset,4):
        if before[i:i+4]!=after[i:i+4]:
            if len(before[i:i+4])!=4:
                raise ValueError('Unaligned prefix relocation')
            a,b=struct.unpack('>I',before[i:i+4])[0],struct.unpack('>I',after[i:i+4])[0]
            if b-a!=8:raise ValueError(f'Unexpected binary patch at {i}: {a}->{b}')
            patches.append(i)
    if len(patches)!=2:
        raise ValueError(f'Expected two source-defined four-byte relocations, found {patches}')
    result={'scope':'RMAC-assembled standalone native model, not linked ROM',
            'rmac_success':True,'old_model_bytes':len(before),'new_model_bytes':len(after),
            'size_delta':len(after)-len(before),'tree_binary_offset':offset,
            'unaltered_tail_bytes':len(before)-(offset+24),
            'rebased_header_word_offsets':patches,
            'old_binary_sha256':hashlib.sha256(before).hexdigest(),
            'new_binary_sha256':hashlib.sha256(after).hexdigest(),
            'negative_empty_link':'0xffff',
            'conclusion':'Rebased assembly has exactly the requested 8-byte tree growth; packed polygon/color payload unchanged'}
    OUT.write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rmac',required=True,type=Path)
    args=p.parse_args()
    print(json.dumps(check(args.rmac.resolve()),indent=2))
