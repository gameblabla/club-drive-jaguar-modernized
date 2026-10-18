#!/usr/bin/env python3
"""Deterministic retained-artifact screenshot regression for source-linked ROM.

Uses a stable build directory instead of temporary emulator file paths. Captures
emulator logs on disk and fails on timeout, hardware errors, or pixel differences.
"""
from pathlib import Path
import argparse,json,hashlib,subprocess,shutil
from PIL import Image,ImageChops
from link_recovered_stage import load_rom,ROOT

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--reference',type=Path,required=True)
 ap.add_argument('--source',type=Path,required=True);ap.add_argument('--emulator',type=Path,required=True)
 ap.add_argument('--frames',type=int,default=1800);ap.add_argument('--interval',type=int,default=300)
 ap.add_argument('--output-report',type=Path,default=ROOT/'build/source_validation.json')
 args=ap.parse_args()
 if args.frames%args.interval or not 1<=args.frames<=3600:raise ValueError('Invalid frame count/interval')
 ref=load_rom(args.reference);rom=load_rom(args.source)
 if len(ref)!=len(rom) or len(rom)!=2097152:raise ValueError('Expected two 2 MiB cartridges')
 if ref[0x400:0x408]!=rom[0x400:0x408] or rom[0x400:0x408]!=bytes.fromhex('0404040400802000'):
  raise ValueError('Jaguar entry header mismatch')
 directory=ROOT/'build/gpu_link_test_output';directory.mkdir(parents=True,exist_ok=True)
 report={'status':'PENDING','bios':'real','frames':args.frames,'interval':args.interval,
  'reference_sha256':hashlib.sha256(ref).hexdigest(),
  'source_sha256':hashlib.sha256(rom).hexdigest(),'pixel_matches':{},'hardware_warning_counts':{}}
 for name,data in [('retail',ref),('source',rom)]:
  cart=directory/f'{name}.j64';cart.write_bytes(data)
  cmd=[str(args.emulator.resolve()),str(cart),'--bios','real','--frames',str(args.frames),
   '--input-script',str((ROOT/'build/gameplay_inputs.txt').resolve()),
   '--png',str(directory/f'{name}.png'),'--png-every',str(args.interval),
   '--debug-bundle',str(directory/f'{name}_debug')]
  with (directory/f'{name}.log').open('w') as logfile:
   try:subprocess.run(cmd,stdout=logfile,stderr=subprocess.STDOUT,timeout=75,check=True)
   except subprocess.TimeoutExpired as e:raise RuntimeError(f'{name} emulator timed out; inspect {logfile.name}') from e
  warnings=json.loads((directory/f'{name}_debug/hardware_warnings.json').read_text())
  report['hardware_warning_counts'][name]=len(warnings)
  if warnings:raise RuntimeError(f'{name} emulator reported {len(warnings)} GPU warnings')
 for field in range(args.interval,args.frames+1,args.interval):
  a=directory/f'retail_{field:06d}.png';b=directory/f'source_{field:06d}.png'
  if not a.exists() or not b.exists():raise RuntimeError(f'Missing comparison screenshot at field {field}')
  img1=Image.open(a).convert('RGB');img2=Image.open(b).convert('RGB')
  ok=img1.size==img2.size and ImageChops.difference(img1,img2).getbbox() is None
  report['pixel_matches'][str(field)]=ok
  print('Field',field, 'EXACT' if ok else 'DIFFERENT',flush=True)
  if not ok:raise RuntimeError(f'Source rendering differs from retail at field {field}')
 report['status']='PASS: real BIOS, zero warnings, exact gameplay screenshots'
 args.output_report.parent.mkdir(parents=True,exist_ok=True)
 args.output_report.write_text(json.dumps(report,indent=2)+'\n')
 print(report['status'])
if __name__=='__main__':main()
