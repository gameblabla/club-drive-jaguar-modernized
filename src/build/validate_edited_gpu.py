#!/usr/bin/env python3
"""Real-BIOS smoke test for intentionally modified, non-retail-exact worlds."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent

def main():
 p=argparse.ArgumentParser();p.add_argument('--rom',type=Path,required=True)
 p.add_argument('--emulator',type=Path,required=True);p.add_argument('--frames',type=int,default=720)
 a=p.parse_args();rom=(ROOT/a.rom).resolve() if not a.rom.is_absolute() else a.rom
 blob=rom.read_bytes()
 if len(blob)!=2097152 or blob[0x400:0x408]!=bytes.fromhex('0404040400802000'):
  raise ValueError('Incorrect Jaguar ROM size, marker, or entry')
 with tempfile.TemporaryDirectory(prefix='club_edited_smoke_') as td:
  tmp=Path(td)
  cmd=[str(a.emulator.resolve()),str(rom),'--bios','real','--frames',str(a.frames),
   '--input-script',str((ROOT/'build/gameplay_inputs.txt').resolve()),
   '--png',str(tmp/'screen.png'),'--debug-bundle',str(tmp/'debug')]
  result=subprocess.run(cmd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
  (ROOT/'build/gpu_link_edited_smoke.log').write_text(result.stdout)
  if result.returncode:raise RuntimeError(f'Edited ROM boot failed: {result.stdout[-700:]}')
  warnings=json.loads((tmp/'debug/hardware_warnings.json').read_text())
  if warnings:raise RuntimeError(f'{len(warnings)} hardware warnings in edited build')
  screen=Image.open(tmp/'screen.png').convert('RGB')
  if len(screen.getcolors(1000000) or [])<12:raise RuntimeError('Display appears blank or uninitialized')
  report={'result':'PASS','fields':a.frames,'bios':'real','gpu_hardware_warnings':0,
   'cartridge_sha256':hashlib.sha256(blob).hexdigest(),
   'screen_dimensions':list(screen.size),'note':'Edited world does not need to match retail screenshots'}
  (ROOT/'build/gpu_link_edited_validation.json').write_text(json.dumps(report,indent=2)+'\n')
  print('Edited world ROM real-BIOS smoke test passed:',a.frames,'fields')
if __name__=='__main__':main()
