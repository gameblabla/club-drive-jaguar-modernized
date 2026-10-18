#!/usr/bin/env python3
"""Repeatable, retained-file comparison without Virtual Jaguar debug-bundles.

Long runs sometimes stall when the emulator's debug-bundle capture is enabled.
This harness avoids that optional capture. It still enforces a per-ROM timeout,
zero process errors, and exact screenshots; warnings in logs fail the test.
"""
from pathlib import Path
import argparse,hashlib,json,re,subprocess
from PIL import Image,ImageChops
from link_recovered_stage import load_rom

def main():
 p=argparse.ArgumentParser()
 p.add_argument('--reference',type=Path,required=True)
 p.add_argument('--source',type=Path,required=True)
 p.add_argument('--emulator',type=Path,required=True)
 p.add_argument('--input-script',type=Path,default=Path(__file__).parent/'gameplay_inputs.txt')
 p.add_argument('--output-dir',type=Path,default=Path(__file__).parent/'cpu_layout_long_test')
 p.add_argument('--frames',type=int,default=3600)
 p.add_argument('--interval',type=int,default=600)
 p.add_argument('--timeout',type=int,default=100)
 a=p.parse_args()
 if not 60<=a.frames<=3600 or a.frames%a.interval:raise ValueError('Unsupported frame count')
 d=a.output_dir.resolve();d.mkdir(parents=True,exist_ok=True)
 ref,src=load_rom(a.reference),load_rom(a.source)
 if len(ref)!=len(src) or len(src)!=0x200000:raise ValueError('Expected 2 MiB ROMs')
 report={'real_bios':True,'emulated_fields':a.frames,'interval':a.interval,
         'retail_sha256':hashlib.sha256(ref).hexdigest(),
         'source_sha256':hashlib.sha256(src).hexdigest(),
         'exact_rgb_screenshots':{},'hardware_warnings_in_log':{}}
 for name,rom in [('retail',ref),('source',src)]:
  f=d/f'{name}.j64';f.write_bytes(rom)
  cmd=[str(a.emulator.resolve()),str(f),'--bios','real','--frames',str(a.frames),
       '--input-script',str(a.input_script.resolve()),
       '--png',str(d/f'{name}.png'),'--png-every',str(a.interval)]
  logfile=d/f'{name}.log'
  with logfile.open('w') as log:
   subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=a.timeout)
  data=logfile.read_text(errors='replace')
  # Do not flag ordinary mention of '--warning' or informational headings.
  warnings=[line for line in data.splitlines() if re.search(r'(\[GPU WARN\]|hardware warning|invalid GPU branch)',line,re.I)]
  report['hardware_warnings_in_log'][name]=warnings
  if warnings:raise RuntimeError(f'{name} reported hardware errors: {warnings[:3]}')
 for field in range(a.interval,a.frames+1,a.interval):
  aimg=d/f'retail_{field:06d}.png';bimg=d/f'source_{field:06d}.png'
  if not aimg.is_file() or not bimg.is_file():raise RuntimeError(f'Screenshot missing at {field}')
  img1=Image.open(aimg).convert('RGB');img2=Image.open(bimg).convert('RGB')
  ok=img1.size==img2.size and ImageChops.difference(img1,img2).getbbox() is None
  report['exact_rgb_screenshots'][str(field)]=ok
  print(f'field {field}: '+('EXACT' if ok else 'DIFF'),flush=True)
  if not ok:raise RuntimeError(f'Visual mismatch at field {field}')
 report['result']='PASS'
 (d/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 print('PASS 3600-field source/retail real-BIOS screenshot parity' if a.frames==3600 else 'PASS source/retail screenshot parity')
if __name__=='__main__':main()
