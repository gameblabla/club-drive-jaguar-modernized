#!/usr/bin/env python3
"""Strict same-offset comparison of source-linked CPU code versus 1994 retail.

The code regions are *source-file landmarks* verified against retail. This
isn't a ROM equivalence proof: relocated resource addresses differ and
asset generation is not yet a historically identical build process.
"""
from pathlib import Path
import argparse, hashlib, json, struct
from link_recovered_stage import load_rom, ROOT

REGIONS = [
    ('cpu_main_2000_ba00',0x2000,0xBA00),
    ('car_model_data_b8e0_fb7c',0xB8E0,0xFB7C),
    ('model_tables_fb80_10f9a',0xFB80,0x10F9A),
    ('gpu_fixup_11048_11178',0x11048,0x11178),
    ('replay_through_modem_11e00_12099',0x11E00,0x12099),
    ('candidate_cpu_text_2000_1ba00',0x2000,0x1BA00),
    ('candidate_cpu_scan_2000_1d000',0x2000,0x1D000),
]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--reference',type=Path,required=True)
    ap.add_argument('--source',type=Path,required=True)
    ap.add_argument('--previous',type=Path,help='Prior gpu_link linked ROM for improvement metrics')
    ap.add_argument('--output',type=Path,default=ROOT/'build/cpu_same_offset.json')
    a=ap.parse_args()
    ref=load_rom(a.reference);src=load_rom(a.source)
    previous=load_rom(a.previous) if a.previous else None
    if len(ref)!=len(src)!=0x200000 or len(ref)!=0x200000:raise ValueError('Expected 2 MiB cartridges')
    if previous and len(previous)!=0x200000:raise ValueError('Incorrect baseline size')
    if src[0x400:0x408]!=bytes.fromhex('0404040400802000'):raise ValueError('Cartridge header/entry corrupted')
    exe=(ROOT/'build/source_link_trial.abs').read_bytes()
    if exe[:2]!=b'\x60\x1b':raise ValueError('Missing Atari executable image')
    size=struct.unpack_from('>I',exe,2)[0]
    result={'reference_sha256':hashlib.sha256(ref).hexdigest(), 'source_sha256':hashlib.sha256(src).hexdigest(),
       'previous_sha256':hashlib.sha256(previous).hexdigest() if previous else None,
       'source_text_bytes':size, 'rom_bytes':len(src),
       'whole_cartridge_difference_bytes':sum(x!=y for x,y in zip(ref,src)),
       'header_difference_bytes':sum(x!=y for x,y in zip(ref[:0x2000],src[:0x2000])),
       'regions':[],'limitations':'These compare bytes at identical cartridge offsets. The source ROM still relocates resource data, includes recovered retail inputs, and is not globally byte-identical.'}
    for label,lo,hi in REGIONS:
        row={'name':label,'start':hex(lo),'end_exclusive':hex(hi),'bytes':hi-lo,
             'same_offset_identical_bytes':sum(x==y for x,y in zip(ref[lo:hi],src[lo:hi]))}
        if previous:
            row['gpu_link_identical_bytes']=sum(x==y for x,y in zip(ref[lo:hi],previous[lo:hi]))
        result['regions'].append(row)
        print(f'{label}: {row["same_offset_identical_bytes"]}/{hi-lo}' + (f' (prior {row["gpu_link_identical_bytes"]})' if previous else ''))
    # Two independently located landmarks fully match retail, protecting the
    # original car data tables and replay-loop alignment from future regressions.
    for name in ('car_model_data_b8e0_fb7c','model_tables_fb80_10f9a','replay_through_modem_11e00_12099'):
        row=next(x for x in result['regions'] if x['name']==name)
        if row['same_offset_identical_bytes']!=row['bytes']:raise RuntimeError(f'Historical CPU landmark {name} lost exact alignment')
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(result,indent=2)+'\n')
    print('PASS: strict retail CPU landmarks and cartridge marker')
if __name__=='__main__':main()
