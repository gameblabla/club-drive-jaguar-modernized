#!/usr/bin/env python3
"""Fail-closed checks for independently linked CPU fix and separately reconstructed retail release window."""
from pathlib import Path
from link_recovered_stage import load_rom,ROOT
import argparse,hashlib,json
p=argparse.ArgumentParser()
p.add_argument('--reference',type=Path,required=True)
p.add_argument('--source',type=Path,required=True)
p.add_argument('--release-window',type=Path,default=ROOT/'assets/native/rom/source/release_layout_verified.bin')
a=p.parse_args();ret=load_rom(a.reference);src=load_rom(a.source);reb=a.release_window.read_bytes()
if len(src)!=0x200000 or len(ret)!=0x200000:raise RuntimeError('Unexpected ROM length')
if src[0x6430:0x6432]!=ret[0x6430:0x6432] or src[0x642e:0x6432]!=bytes.fromhex('183cffff'):
 raise RuntimeError('HISCORE retail sign-extended immediate missing')
if src[0x400:0x408]!=bytes.fromhex('0404040400802000'):raise RuntimeError('Jaguar boot marker missing')
if reb!=ret[0x13574:0x1d000]:raise RuntimeError('Release layout source no longer matches retail')
match=sum(x==y for x,y in zip(src[0x2000:0x1ba00],ret[0x2000:0x1ba00]))
if match<71873:raise RuntimeError(f'CPU source parity regressed: {match}')
report={'independent_source_rom_sha256':hashlib.sha256(src).hexdigest(),
        'reference_rom_sha256':hashlib.sha256(ret).hexdigest(),
        'same_offset_matches_0x2000_0x1ba00':match,
        'retail_window_size':len(reb),
        'retail_window_identical_bytes':len(reb),
        'retail_window_source_sha256':hashlib.sha256(reb).hexdigest(),
        'distinction':'Window is separately assembled from GPU source binaries and ROM-disassembled helper code; this is NOT installed in the independent ROM and must not be counted as independent ROM matches.'}
(ROOT/'build/retail_overlay_audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS retail_overlay CPU exact immediate and separate release-code source block:',match,'CPU same-offset matches;',len(reb),'bytes retail layout')
