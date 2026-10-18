#!/usr/bin/env python3
"""Rebuild original GPU RMAC listings and extract collision probe addresses.

Usage: python3 GPU_TRACE/emulator/prepare_symbols.py /path/to/rmac
Writes listings/binaries alongside this helper (NOT into the clean build inputs).
"""
from pathlib import Path
import argparse,json,re,subprocess

HERE=Path(__file__).resolve().parent
ROOT=HERE.parent.parent
OUT=HERE/'listings'
LABELS={
    'casend':['drvloop','closetop','closeLp','crashlp','crashedge','edgehit','enterclose','doneclose','drvloopend'],
    'racend':['drvloop','closetop','closeLp','crashlp','crashedge','edgehit','enterclose','doneclose','drvloopend'],
    'tagend':['drvloop','closetop','closeLp','crashlp','crashedge','edgehit','enterclose','doneclose','drvloopend'],
    'comp':['initit','forlp','innerfor','endforlp'],
    'precomp':[]
}

def compile_labels(rmac):
    OUT.mkdir(exist_ok=True)
    result={}
    for module,labels in LABELS.items():
        lst=OUT/f'{module}.lst';dest=OUT/f'{module}.bin'
        source=ROOT/'build/compat_gpu'/f'{module}.gas'
        cmd=[str(rmac),'-dCOMPAT=0','-mtom','-fr','-l*'+str(lst),'-o',str(dest),str(source)]
        run=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,timeout=60)
        if run.returncode:raise RuntimeError(f'{module} assembler failed: {run.stdout+run.stderr}')
        original=ROOT/'build/gpu'/f'{module}.bin'
        if dest.read_bytes()!=original.read_bytes():raise ValueError(f'{module}: generated image differs from contact_audit assembler output')
        listing=lst.read_text(errors='replace')
        found={}
        for label in labels:
            m=re.search(r'(?im)^\s+'+re.escape(label)+r'\s+0{5,}([0-9A-F]{6})\s+a\b',listing)
            if not m:raise ValueError(f'{module}: {label} not found in RMAC symbol listing')
            found[label]=int(m.group(1),16)
        if module in ('casend','racend','tagend'):
            body=listing[listing.find('update car forces, etc.'):]
            m=re.search(r'(?im)^\s*\d+\s+([0-9A-F]{8})\s+[0-9A-F]{4}\s+store\s+r2,\(r29\)',body)
            if not m:raise ValueError(f'{module}: force store not found in listing')
            found['force_store']=0xF03038+int(m.group(1),16)
        result[module]=found
    expected=json.loads((HERE.parent/'gpu_addresses.json').read_text())
    if result!=expected:raise ValueError('Assembled symbols differ from shipped trace addresses')
    print('GPU_TRACE original GPU assembler binaries and 34 symbol targets: exact match')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('rmac',type=Path)
    compile_labels(parser.parse_args().rmac)
