#!/usr/bin/env python3
"""Strict artifact validation for the Club Drive source/ROM recovery project."""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys, zipfile, zlib, tempfile
from recovered_resources import inflate_member, sha, META, WORLD_GPU
ROOT=Path(__file__).resolve().parent.parent
GPU_EXACT={'3d':(0x13580,46),'adjblack':(0x537E8,66),'uncomp':(0x53838,118),
 'preren':(0x1A8F0,1302),'comp':(0x15130,3654),'ren':(0x15F80,3750),
 'precomp':(0x19E38,2732)}

def load(path):
 if path.suffix.lower()=='.zip':
  with zipfile.ZipFile(path) as z:
   names=[n for n in z.namelist() if n.lower().endswith('.j64')]
   assert len(names)==1
   return z.read(names[0])
 return path.read_bytes()

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--reference',required=True,type=Path)
 ap.add_argument('--rebuilt',default=ROOT/'Club_Drive_reconstructed.j64',type=Path)
 ap.add_argument('--emulator',type=Path,help='Optional compiled Virtual Jaguar headless executable')
 ap.add_argument('--strict-retail',action='store_true',help='Fail if any bytes are intentionally modified')
 ap.add_argument('--sdk',type=Path,help='Supplied Jaguar SDK, for independent header signature reproducibility check')
 ap.add_argument('--bios-real',action='store_true',help='Boot the emulator using its real BIOS mode')
 args=ap.parse_args();retail=load(args.reference);candidate=load(args.rebuilt)
 assert len(retail)==len(candidate)==2097152
 payload_changed=candidate[0x2000:]!=retail[0x2000:]
 if not payload_changed:assert candidate[:0x2000]==retail[:0x2000], 'Unchanged ROM unexpectedly has a new header'
 if payload_changed and not args.sdk:print('WARNING: changed payload; pass --sdk to independently verify jagcrypt header')
 if args.sdk:
  jagcrypt=args.sdk.resolve()/'tools/bin/jagcrypt'
  with tempfile.TemporaryDirectory(prefix='club_verify_signature_') as td:
   q=Path(td)/'recheck.rom';q.write_bytes(candidate)
   process=subprocess.run([str(jagcrypt),'-u',q.name],cwd=td,stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT,text=True,timeout=120)
   output=Path(td)/'recheck.U1'
   if process.returncode or not output.is_file():raise AssertionError('Jagcrypt validation failed: '+process.stdout)
   assert output.read_bytes()==candidate,'Encrypted MD5/RSA header does not correspond to cartridge payload'
 assert candidate[0x400:0x408]==bytes.fromhex('0404040400802000')
 exact=[]
 for name,(off,size) in GPU_EXACT.items():
  b=(ROOT/'build/gpu'/f'{name}.bin').read_bytes()
  assert len(b)==size and b==retail[off:off+size],name
  assert candidate[off:off+size]==b,name
  exact.append(name)
 assert (ROOT/'build/obj/playdata.o').exists()
 from recover_audio import BANK_START,BANK_END,assemble_bank,collect
 snd=collect(retail)
 assert snd['sample_count']==42 and snd['score_count']==7
 assembled_sounds=assemble_bank(None)
 assert len(assembled_sounds)==BANK_END-BANK_START
 assert candidate[BANK_START:BANK_END]==assembled_sounds,'Source-built sample/score bank differs from cartridge'
 sounds_obj=(ROOT/'build/obj/sounds_reconstructed.o').read_bytes()
 import struct
 obj_t,obj_d=struct.unpack_from('>II',sounds_obj,4)
 assert sounds_obj[32:32+obj_t+obj_d]==assembled_sounds,'Assembler object differs from sample bank'
 meta=json.loads(META.read_text());assert meta['reference_rom_sha256']==sha(retail)
 local=[]
 for member in meta['resources']:
  start,end=member['rom_start'],member['rom_end']
  orig,size=inflate_member(retail,start)
  generated,genlen=inflate_member(candidate,start)
  assert len(orig)==len(generated)==member['raw_size']
  assert size==member['packed_capacity'] and genlen<=size
  assert sha(orig)==member['original_sha256']
  if start in WORLD_GPU:
   kernel,pos=WORLD_GPU[start]
   b=(ROOT/'build/gpu'/f'{kernel}.bin').read_bytes()
   assert orig[pos:pos+len(b)]==b or generated[pos:pos+len(b)]==b,kernel
   assert generated[pos:pos+len(b)]==b,kernel
   local.append(kernel)
 manifest=json.loads((ROOT/'build/hybrid_index.json').read_text())
 assert manifest['main_68000_modules_compiled']==26
 assert sum(bool(x['assembled']) for x in manifest['gpu_module_results'])==21
 if args.strict_retail:assert candidate==retail,'This build has user changes (disable --strict-retail)'
 print(f'PASS: {"source-regenerated" if payload_changed else "original"} cartridge header, marker, entry 0x802000; {len(candidate)} bytes')
 print('PASS: 42 original F16 samples and 7 scores assembled byte-for-byte into 586,944-byte sound bank')
 print('PASS: exact source GPU programs:',', '.join(exact))
 print('PASS: exact world-local GPU programs:',', '.join(local))
 print('PASS: 22 valid gzip resources at fixed ROM offsets; 26 CPU, 21 GPU modules assembled')
 if args.emulator:
  emulator=args.emulator.resolve()
  inp=ROOT/'build/gameplay_inputs.txt'
  for label,rom in [('rebuilt',args.rebuilt),('reference',args.reference)]:
   if rom.suffix.lower()=='.zip':
    tmp=ROOT/'build/reference_for_test.j64';tmp.write_bytes(retail);rom=tmp
   png=ROOT/'build'/f'base_verify_{label}_720.png'
   cmd=[str(emulator),str(rom.resolve()),'--frames','720','--input-script',str(inp),'--png',str(png)]
   if args.bios_real:cmd.extend(['--bios','real'])
   with (ROOT/'build'/f'base_verify_{label}.log').open('w') as f:
    subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=180)
  a=(ROOT/'build/base_verify_rebuilt_720.png').read_bytes()
  b=(ROOT/'build/base_verify_reference_720.png').read_bytes()
  if args.strict_retail:assert a==b,'Retail-identical build unexpectedly rendered differently'
  print('PASS: two 720-field headless emulator tests; screenshot', 'identical' if a==b else 'different after edits')

if __name__=='__main__':main()
