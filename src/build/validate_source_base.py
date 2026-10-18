#!/usr/bin/env python3
"""Boot both cartridges with real BIOS and compare deterministic title/loading frames.

Longer gameplay diverges after about 900 fields; that is documented, never
claimed as a pass.  Use the same scripted input for both games.
"""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile,struct,sys
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parent.parent

def readrom(file):
 from link_recovered_stage import load_rom
 return load_rom(file)

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--reference',type=Path,required=True)
 p.add_argument('--source',type=Path,required=True)
 p.add_argument('--emulator',type=Path,required=True)
 p.add_argument('--output-report',type=Path,default=ROOT/'build/source_validation.json')
 a=p.parse_args();reference=readrom(a.reference);source=readrom(a.source)
 assert len(reference)==len(source)==2*1024*1024
 assert reference[0x400:0x408]==source[0x400:0x408]==bytes.fromhex('0404040400802000')
 assert reference[0x2000:]!=source[0x2000:],'Not an independent rebuilt payload'
 exe=a.emulator.resolve();assert exe.is_file()
 result={'reference_sha256':hashlib.sha256(reference).hexdigest(),'source_sha256':hashlib.sha256(source).hexdigest(),
         'independent_executable':True,'cart_size':len(source),'header_marker':source[0x400:0x408].hex(),
         'bios_mode':'real','tested_fields':720,'equal_frames':{},'emulation':{}}
 with tempfile.TemporaryDirectory(prefix='club_') as td:
  t=Path(td)
  # The emulator requires a file suffix for the input cartridge.
  (t/'retail.j64').write_bytes(reference)
  (t/'source.j64').write_bytes(source)
  for name in ['retail','source']:
   cmd=[str(exe),str(t/f'{name}.j64'),'--bios','real','--frames','720',
      '--input-script',str(ROOT/'build/gameplay_inputs.txt'),'--png',str(t/f'{name}.png'),
      '--png-every','180','--debug-bundle',str(t/f'{name}_debug')]
   p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
   (ROOT/f'build/gpu_base_emulator_{name}.log').write_text(p.stdout)
   if p.returncode:raise RuntimeError(f'{name} emulator failed: {p.stdout[-1000:]}')
   regs=json.loads((t/f'{name}_debug/registers.json').read_text());warnings=json.loads((t/f'{name}_debug/hardware_warnings.json').read_text())
   result['emulation'][name]={'pc68k':hex(regs['pc68k']),'gpu_pc':hex(regs['gpu_pc']),
       'warning_count':len(warnings),'warning_hits':sum(w['hits'] for w in warnings)}
   if warnings:raise RuntimeError(f'{name} reported {len(warnings)} hardware warnings')
  for frame in [180,360,540,720]:
   p1=t/f'retail_{frame:06d}.png';p2=t/f'source_{frame:06d}.png'
   if not p1.exists() or not p2.exists():raise ValueError(f'Missing emulator snapshot at {frame} fields')
   i1=Image.open(p1).convert('RGB');i2=Image.open(p2).convert('RGB')
   exact=i1.size==i2.size and ImageChops.difference(i1,i2).getbbox() is None
   result['equal_frames'][str(frame)]={'equal':exact,'source_image_sha256':hashlib.sha256(p2.read_bytes()).hexdigest()}
   if not exact:raise RuntimeError(f'Source-linked build differs from retail at field {frame}')
  # Save a useful representative screenshot outside transient temp directory.
  (ROOT/'build/source_title.png').write_bytes((t/'source_000540.png').read_bytes())
 result['result']='PASS: authenticated rebuilt 68K title/loading path matches retail at 180,360,540,720; gameplay after 900 unresolved'
 a.output_report.parent.mkdir(parents=True,exist_ok=True);a.output_report.write_text(json.dumps(result,indent=2)+'\n')
 print(result['result'])
if __name__=='__main__':main()
