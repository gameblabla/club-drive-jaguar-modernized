#!/usr/bin/env python3
"""Exact screenshot regression of an independently linked Club Drive cartridge.

Checks identical screenshots at regular intervals using the supplied Jaguar BIOS,
not just successful emulator exit. Provides optional extended 3600-field tests.
"""
from pathlib import Path
import argparse, hashlib, json, subprocess, tempfile
from PIL import Image, ImageChops
from link_recovered_stage import load_rom
ROOT=Path(__file__).resolve().parent.parent

def run():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--reference',type=Path,required=True)
 p.add_argument('--source',type=Path,required=True)
 p.add_argument('--emulator',type=Path,required=True)
 p.add_argument('--frames',type=int,choices=[1800,3600],default=1800)
 p.add_argument('--input-script',type=Path,default=ROOT/'build/gameplay_inputs.txt')
 p.add_argument('--output-report',type=Path,default=ROOT/'build/source_validation.json')
 a=p.parse_args()
 source=load_rom(a.source);reference=load_rom(a.reference)
 assert len(source)==len(reference)==2097152
 assert source[0x400:0x408]==reference[0x400:0x408]==bytes.fromhex('0404040400802000')
 assert source[0x2000:]!=reference[0x2000:], 'This is not the independent rebuilt executable'
 interval=300 if a.frames==1800 else 600
 snapshot_frames=list(range(interval,a.frames+1,interval))
 report={'result':'pending','bios':'real','frames':a.frames,'image_interval':interval,
   'reference_sha256':hashlib.sha256(reference).hexdigest(),
   'source_sha256':hashlib.sha256(source).hexdigest(),
   'reference_and_source_full_rom_identical':source==reference,
   'source_68000_payload_differs_from_retail':source[0x2000:]!=reference[0x2000:],
   'screenshots':{},'hardware_warning_counts':{},'input_script':str(a.input_script)}
 with tempfile.TemporaryDirectory(prefix='club_compare_') as td:
  temp=Path(td)
  for n,data in [('retail',reference),('source',source)]:
   (temp/f'{n}.j64').write_bytes(data)
   cmd=[str(a.emulator.resolve()),str(temp/f'{n}.j64'),'--bios','real','--frames',str(a.frames),
     '--input-script',str(a.input_script.resolve()),'--png',str(temp/f'{n}.png'),
     '--png-every',str(interval),'--debug-bundle',str(temp/f'{n}_debug')]
   done=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=150)
   (ROOT/f'build/gpu_check_emulator_{n}_{a.frames}.log').write_text(done.stdout)
   if done.returncode:raise RuntimeError(f'{n} emulator failed: {done.stdout[-1200:]}')
   warn=json.loads((temp/f'{n}_debug/hardware_warnings.json').read_text())
   report['hardware_warning_counts'][n]=len(warn)
   if warn:raise RuntimeError(f'{n} had {len(warn)} emulator hardware warnings')
  for f in snapshot_frames:
   a1=temp/f'retail_{f:06d}.png';b1=temp/f'source_{f:06d}.png'
   if not a1.exists() or not b1.exists():raise RuntimeError(f'Missing frame {f} screen')
   img1=Image.open(a1).convert('RGB');img2=Image.open(b1).convert('RGB')
   equal=(img1.size==img2.size and ImageChops.difference(img1,img2).getbbox() is None)
   report['screenshots'][str(f)]={'pixel_exact':equal,'frame_sha256':hashlib.sha256(b1.read_bytes()).hexdigest()}
   print(f'Field {f}: '+('PIXEL-EXACT' if equal else 'DIFFERENT'))
   if not equal:raise RuntimeError(f'Field {f} differs from retail')
  (ROOT/'build/source_gameplay.png').write_bytes((temp/f'source_{a.frames:06d}.png').read_bytes())
 report['result']='PASS: all compared gameplay screenshots are pixel-exact to retail; full cartridge ROM is not binary-identical'
 a.output_report.parent.mkdir(parents=True,exist_ok=True)
 a.output_report.write_text(json.dumps(report,indent=2)+'\n')
 print(report['result'])
if __name__=='__main__':run()
