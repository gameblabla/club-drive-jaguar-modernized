#!/usr/bin/env python3
"""Extract original non-GASM 68000/GPU compression helpers & JPEG tables.

Addresses are not inferred from file order. ROM loads of #dehuff, #dejagst,
#q75 and #q85 in original sys.s are located by their surrounding instruction
bytes and checked against source-defined GPU and JPEG register destinations.
The binary helper implementations are not source reconstructed yet.
"""
from pathlib import Path
import sys, hashlib, struct, json
from link_recovered_stage import load_rom
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/native/tools'
REF_SHA='dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289'

def addr_in_pattern(rom, lead, tail):
    # lead is instruction with a 32-bit relocation immediately following
    idx=[]; i=0
    while (i:=rom.find(lead,i))!=-1:
        e=i+len(lead)
        if rom[e+4:e+4+len(tail)]==tail:
            idx.append((i,struct.unpack_from('>I',rom,e)[0]))
        i+=1
    if len(idx)!=1:raise ValueError(f'Expected unique sys.s code signature {lead.hex()}; found {idx}')
    return idx[0]

def main(p):
    rom=load_rom(Path(p));assert hashlib.sha256(rom).hexdigest()==REF_SHA
    # sys.s ld_decmp: lea dejagst,a0; bsr load_gpu; move.l #dehuff,$f03f48; rts
    pos,dej=addr_in_pattern(rom,bytes.fromhex('41f9'),bytes.fromhex('6100001c23fc'))
    if rom[pos+10:pos+12]!=b'\x23\xfc':raise ValueError('Unexpected ld_decmp layout')
    deh=struct.unpack_from('>I',rom,pos+12)[0]
    if rom[pos+16:pos+22]!=bytes.fromhex('00f03f484e75'):raise ValueError('Dehuff GPU register match failed')
    # sys.s load_q75/load_q85: move.l #q75,A2_BASE; bra.b ld_dq; move.l #q85,A2_BASE
    qsig=bytes.fromhex('23fc')
    matches=[]; i=0
    while (i:=rom.find(qsig,i))!=-1:
        a=i+2
        if rom[a+4:a+10]==bytes.fromhex('00f02224600a') and rom[a+10:a+12]==qsig and rom[a+16:a+20]==bytes.fromhex('00f02224'):
            matches.append((i,struct.unpack_from('>I',rom,a)[0],struct.unpack_from('>I',rom,a+12)[0]))
        i+=1
    if len(matches)!=1:raise ValueError('Unable to identify both Jaguar DQ table addresses: '+repr(matches))
    _,q75,q85=matches[0]
    # Recovered titlebkg pointer table locates the next decompression resource,
    # not a guessed helper length.
    from recover_graphics_assets import locate
    title=min(x['start'] for x in locate(rom))
    points={'dehuff':deh-0x800000, 'q75':q75-0x800000, 'q85':q85-0x800000,'dejagst':dej-0x800000}
    if points['q85']-points['q75']!=320 or title-points['q85']!=320:
        raise ValueError('JPEG quantization tables not contiguous 320-byte regions')
    if not (0<points['dehuff']<points['q75']<points['q85']<title<points['dejagst']<0x537E8):
        raise ValueError('Recovered helper addresses are outside expected cartridge sections')
    ends={'dehuff':points['q75'],'q75':points['q85'],'q85':title,'dejagst':0x537E8}
    OUT.mkdir(parents=True,exist_ok=True)
    out=[]
    for label in points:
        start,end=points[label],ends[label]
        fn=label+'.bin'
        data=rom[start:end];(OUT/fn).write_bytes(data)
        out.append({'symbol':label,'original_filename':fn,'start':start,'slot_end':end,'length':len(data),
                    'sha256':hashlib.sha256(data).hexdigest(),'evidence':'sys.s instruction relocation; independent neighboring original section boundary'})
    (OUT/'helpers_index.json').write_text(json.dumps({'reference_sha256':REF_SHA,'resources':out,'note':'Retained native binaries are not yet reconstructed source. Exact offsets derived from CPU instructions.'},indent=2)+'\n')
    for x in out: print(x['symbol'],hex(x['start']),x['length'],'bytes')
if __name__=='__main__':
 if len(sys.argv)!=2: raise SystemExit('Usage: recover_binary_helpers.py retail.zip|j64')
 main(sys.argv[1])
