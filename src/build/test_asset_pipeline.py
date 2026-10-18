#!/usr/bin/env python3
"""Regression: changing one editable PNG pixel produces one ROM-byte change,
with encrypted header intact and a booting game. Restores PNG and original ROM.
"""
from pathlib import Path
from PIL import Image
import hashlib, json, os, subprocess, tempfile
ROOT=Path(__file__).resolve().parent.parent
ROM=Path('/mnt/data/club_rebuild/Club Drive (World).j64')
SDK=Path('/mnt/data/club_rebuild/jaguar-sdk-linux-x86_64')
EMU=Path('/mnt/data/virtualjaguar-register-viewport-git-repo/virtualjaguar-headless')
PNG=ROOT/'assets/graphics/artwork/dashpal.png'
ORIG=PNG.read_bytes()
reference=ROM.read_bytes()
TEST=ROOT/'build/asset_pipeline_test.j64'
try:
 img=Image.open(PNG)
 px=img.load()
 before=px[17,8]
 px[17,8]=(before+1)&255
 img.save(PNG,optimize=True)
 assert PNG.read_bytes()!=ORIG
 cmd=['python',str(ROOT/'build_reconstructed.py'),'--reference',str(ROM),'--sdk',str(SDK),'--output',str(TEST)]
 p=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,check=True)
 rebuilt=TEST.read_bytes()
 diffs=[i for i,(a,b) in enumerate(zip(reference,rebuilt)) if a!=b]
 assert len(diffs)==1, f'{len(diffs)} diffs'
 assert rebuilt[:0x2000]==reference[:0x2000], 'header changed'
 assert rebuilt[0x2000:0x2020]==reference[0x2000:0x2020], 'game entry changed'
 rom_off=diffs[0]
 assert 0xe5690<=rom_off<0xe5690+19424
 print('Edited pixel at (17,8), ROM changed at',hex(rom_off))
 p=subprocess.run([str(EMU),str(TEST),'--frames','720','--input-script',str(ROOT/'build/gameplay_inputs.txt'),'--png',str(ROOT/'build/asset_pipeline_gameplay.png')],capture_output=True,text=True,check=True)
 assert '[BOOT] Cart game' in p.stdout+p.stderr
 assert '[png]' in p.stdout+p.stderr
 report={'result':'PASS','rom_changed_bytes':len(diffs),'rom_changed_offset':hex(rom_off),'encrypted_header_unchanged':True,'gameplay_720_frames':True,'editable_asset':'assets/graphics/artwork/dashpal.png','pixel_modified':[17,8], 'original_value':before,'edited_value':(before+1)&255}
 (ROOT/'build/asset_pipeline_test.json').write_text(json.dumps(report,indent=2)+'\n')
 print(report)
finally:
 PNG.write_bytes(ORIG)
 # Restore the normal, unmodified retail-identical build output.
 cmd=['python',str(ROOT/'build_reconstructed.py'),'--reference',str(ROM),'--sdk',str(SDK),'--output','/mnt/data/Club_Drive_source_hybrid.j64']
 q=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
 print('Unmodified rebuild status',q.returncode)
 if q.returncode:print(q.stdout, q.stderr)
 if q.returncode==0:assert Path('/mnt/data/Club_Drive_source_hybrid.j64').read_bytes()==reference
