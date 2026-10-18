#!/usr/bin/env python3
"""Compose 1994 GPU-container order as a real, relocatable RLN text object.

Unlike the retail_overlay retail overlay, this object is linked BETWEEN the 68000/DSP
startup sources and the remaining native 68000 helpers. The 12 GPU payloads
come from the contemporary .GAS assembler output; only inter-container
historical alignment words are taken from the byte-verified retail_overlay source.
"""
from pathlib import Path
import argparse,hashlib,subprocess,json,re,struct
from link_recovered_stage import ROOT,load_rom
from reconstruct_retail_layout import START,C_START,GPU_ORDER,LABELS,align

SRC=ROOT/'assets/native/rom/source/RELEASE_GPU.S'
OBJ=ROOT/'assets/native/rom/source/release_gpu.o'

def construct(reference, sdk):
    ref=load_rom(reference)
    source=['; ---------------------------------------------------------------------',
      '; CLUB DRIVE / RELEASE GPU CONTAINERS (1994 ORIGINAL LINK ORDER)',
      '; ---------------------------------------------------------------------',
      '; Entry:    68000 cartridge memory, aligned to eight-byte phrases.',
      '; Input:    GPU programs assembled from the preserved Atari .GAS sources.',
      '; Output:   8-byte Jaguar GPU load descriptor followed by GPU opcodes.',
      '; Register use: none at 68000 runtime; this is constant, read-only data.',
      '; Link note: follow the DSP object, preceding the C/68000 helpers.',
      '; RELEASE_OVERLAY recovery note: only padding words are recovered from retail.',
      '; This is *not* 68000 executable code: the 68000 loader copies it to GPU RAM.',
      '; ---------------------------------------------------------------------',
      '\t.text','club_gpu_begin::']
    current=START+4  # Original linker inserted two NOP words at START.
    manifest=[]
    for name in GPU_ORDER:
        file=ROOT/'build/gpu_link'/f'{name}.bin'
        blob=file.read_bytes()
        if ref[current:current+len(blob)]!=blob:
            raise RuntimeError(f'{name}: source-built GPU container does not match retail @ {current:#x}')
        dest,sz=struct.unpack_from('>II',blob)
        source.extend([f'; {name.upper():<8} ROM {current:#08x}; GPU RAM destination ${dest:08X}, instructions {sz} bytes',
          f'; Source: {name.upper()}.GAS (via build/gpu_link/{name}.bin).',
          f'{LABELS[name]}::',f'\tincbin "build/gpu_link/{name}.bin"'])
        manifest.append(dict(name=name,symbol=LABELS[name],offset=current,container_bytes=len(blob),destination=dest,opcodes_bytes=sz))
        current+=len(blob)
        pad=ref[current:align(current)]
        if len(pad)%2:raise RuntimeError('Odd padding')
        if pad:
            source.extend([f'; {len(pad)} historical alignment byte(s) at ${current:06X}; not GPU instructions.',
                           '\tdc.w '+','.join(f'${int.from_bytes(pad[i:i+2],"big"):04X}' for i in range(0,len(pad),2))])
            current+=len(pad)
    if current!=C_START:raise AssertionError(f'GPU region ends {current:#x} instead of {C_START:#x}')
    source.extend(['club_gpu_end::',''])
    SRC.write_text('\n'.join(source))
    cmd=[str(sdk/'tools/bin/rmac'),'-fb','-u','-o',str(OBJ),str(SRC)]
    p=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
    if p.returncode:raise RuntimeError('Failed GPU object assemble: '+p.stdout+p.stderr)
    sha=hashlib.sha256(ref[START+4:C_START]).hexdigest()
    (ROOT/'assets/native/rom/source/release_gpu.json').write_text(json.dumps(dict(retail_window_start=START+4,retail_window_end=C_START,bytes=C_START-START-4,sha256=sha,containers=manifest,required_linker_padding_words=2),indent=2)+'\n')
    print('Assembled historical source GPU text object:',hex(C_START-(START+4)), 'bytes /',len(manifest),'programs')
    return OBJ

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--reference',required=True,type=Path)
    p.add_argument('--sdk',required=True,type=Path)
    a=p.parse_args()
    construct(a.reference,a.sdk.resolve())
