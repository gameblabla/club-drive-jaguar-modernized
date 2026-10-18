#!/usr/bin/env python3
"""Strict retail-vs-source 1800-field comparison without unstable debug-bundle path."""
import argparse, json, hashlib, subprocess, re
from pathlib import Path
from PIL import Image,ImageChops
from link_recovered_stage import ROOT,load_rom

def main():
 p=argparse.ArgumentParser()
 p.add_argument('--reference',type=Path,required=True)
 p.add_argument('--source',type=Path,required=True)
 p.add_argument('--emulator',type=Path,required=True)
 p.add_argument('--frames',type=int,default=1800)
 p.add_argument('--interval',type=int,default=600)
 p.add_argument('--timeout',type=int,default=90)
 a=p.parse_args()
 assert a.frames%a.interval==0 and a.frames>0
 dir=ROOT/'build/retail_overlay_gameplay_test';dir.mkdir(exist_ok=True,parents=True)
 inputs=ROOT/'build/gameplay_inputs.txt'
 results={'bios':'real','frames':a.frames,'interval':a.interval,'checkpoints':{},'hardware_warnings':{},'status':'UNVERIFIED'}
 for name,b in [('retail',load_rom(a.reference)),('source',load_rom(a.source))]:
  path=dir/f'{name}.j64';path.write_bytes(b)
  results[name+'_sha256']=hashlib.sha256(b).hexdigest()
  cmd=[str(a.emulator.resolve()),str(path.resolve()),'--bios','real','--frames',str(a.frames),'--input-script',str(inputs.resolve()),'--png',str((dir/f'{name}.png').resolve()),'--png-every',str(a.interval)]
  with (dir/f'{name}.log').open('w') as output:
   try:subprocess.run(cmd,cwd=ROOT,stdout=output,stderr=subprocess.STDOUT,check=True,timeout=a.timeout)
   except (subprocess.CalledProcessError,subprocess.TimeoutExpired) as err:raise RuntimeError(f'{name} emulator did not complete; see {dir/name}.log') from err
  log=(dir/f'{name}.log').read_text(errors='replace')
  warnings=sum(1 for line in log.splitlines() if re.search(r'GPU.*(?:warning|invalid|error)|hardware warning',line,re.I))
  results['hardware_warnings'][name]=warnings
  if warnings:raise RuntimeError(f'{name} GPU/hardware warnings: {warnings}')
  print(name,'completed',a.frames,'fields; warnings',warnings,flush=True)
 for field in range(a.interval,a.frames+1,a.interval):
  f=f'{field:06d}'
  images=[Image.open(dir/f'{n}_{f}.png').convert('RGB') for n in ('retail','source')]
  eq=(images[0].size==images[1].size and ImageChops.difference(*images).getbbox() is None)
  results['checkpoints'][f]=eq
  if not eq:raise RuntimeError(f'Field {field} does not match retail')
 results['status']='PASS'
 (ROOT/'build/retail_overlay_gameplay_validation.json').write_text(json.dumps(results,indent=2)+'\n')
 print('PASS',len(results['checkpoints']),'identical RGB frame checkpoints',flush=True)
if __name__=='__main__':main()
