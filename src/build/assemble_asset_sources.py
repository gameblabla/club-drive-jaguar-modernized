#!/usr/bin/env python3
"""Incremental assembly of fixed-layout decoded-resource inputs (2026 notes).

Run AFTER a clean, audited retail_link source link. This intentionally does not re-link
CPU code: changed gzip sizes would move the modern linker's data section and
invalidate the separately verified 141-address retail relocation map. Instead,
recompile the fixed-size asset inputs and let the audio_bank fixed-slot packer apply
them to the verified CPU object baseline. Edited CPU source requires a separate
clean main-code rebuild before this asset step.
"""
from pathlib import Path
import argparse
import subprocess
from graphics_roundtrip import compile_png
from png_art_pipeline import compile_all as compile_art_pngs
from legacy_gpu_compat import Port, OUT

ROOT = Path(__file__).resolve().parent.parent
WORLD_GPU = ('gpustud', 'gpugara', 'gpuhouse', 'gpucity')


def build(sdk):
    rmac = (sdk / 'tools/bin/rmac').resolve()
    if not rmac.is_file():
        raise FileNotFoundError(rmac)
    (ROOT / 'build/gpu').mkdir(parents=True, exist_ok=True)
    (ROOT / 'build/obj').mkdir(parents=True, exist_ok=True)
    # These originals use RMAC 68000 syntax as provided in the repaired retail_data
    # codebase. Preserve module-wide comments and named original symbols.
    compile_png()
    compile_art_pngs()  # ART.S now gets all 147 sprite binaries from editable PNGs.
    for name in ('art', 'playdata', 'inflate'):
        cmd=[str(rmac),'-dCOMPAT=0','-fb','-u',
             *(['+o2'] if name=='inflate' else []),'-icompat_include',
             '-o',str(ROOT/'build/obj'/f'{name}.o'),str(ROOT/('ART.S' if name.lower()=='art' else name.lower()+'.s'))]
        p=subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True,timeout=50)
        if p.returncode:
            raise RuntimeError(f'{name}: 68000 asset assembly failed: {p.stdout} {p.stderr}')
        print('Reassembled source graphics/tables:',name)
    for name in WORLD_GPU:
        out=ROOT/'build/gpu'/f'{name}.bin'
        cmd=[str(rmac),'-dCOMPAT=0','-mtom','-fr','-icompat_include',
             '-o',str(out),str(ROOT/(name.lower()+'.gas'))]
        p=subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True,timeout=50)
        if p.returncode:
            OUT.mkdir(exist_ok=True,parents=True)
            converted=Port().run(name)
            cmd[-1]=str(converted)
            p=subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True,timeout=50)
        if p.returncode:
            raise RuntimeError(f'{name}: world GPU assembly failed: {p.stdout} {p.stderr}')
        print('Reassembled world-local GPU:',name)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk',required=True,type=Path)
    a=parser.parse_args()
    build(a.sdk)


if __name__=='__main__':
    main()
