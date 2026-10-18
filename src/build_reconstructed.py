#!/usr/bin/env python3
"""Reproducible Club Drive assets hybrid cartridge builder.

Compiles original 68000/GPU modules, recovered source graphics, the complete
49-asset audio bank and 22 verified world/graphics gzip resources. Unlinked
68000 and remaining resources are provided by the retail ROM. On changed ROM
payload, the SDK jagcrypt tool regenerates the cartridge RSA/MD5 boot block.
This is *not* a self-contained source-linked gameplay executable.
"""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, struct, sys, zipfile, tempfile

ROOT=Path(__file__).resolve().parent
MODULES='game sys input title select credits hiscore eeprim sound tables remote play mkmat blit gpufix playinp td modem readjoy playdata mktp alloc lattice inflate packet art'.split()
GPU='adjblack uncomp lighten cross fade gpunzip comp precomp ren preren casbeg racbeg tagbeg casend racend tagend 3d gpustud gpuhouse gpugara gpucity'.split()
EXACT_GPU={'3d':(0x13580,46),'adjblack':(0x537E8,66),'uncomp':(0x53838,118),'preren':(0x1A8F0,1302),
           'comp':(0x15130,3654),'ren':(0x15F80,3750),'precomp':(0x19E38,2732)}
ORIGINAL_SHA='dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289'
FONT=bytes.fromhex('3e033e3e633e3e3e3e3e3e7c3e783e3e')

def sdk_assembler(sdk):
 exe=sdk/'tools/bin/rmac'
 if not exe.is_file():raise SystemExit('Supplied SDK rmac not found: '+str(exe))
 return str(exe)

def run(cmd, log):
 p=subprocess.run(cmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
 Path(log).write_text(p.stdout)
 return p.returncode==0

def section(p):
 b=p.read_bytes()
 if b[:4]!=b'\x00\x00\x01\x07':raise ValueError('Not an RMAC BSD object: '+str(p))
 t,d=struct.unpack_from('>II',b,4)
 return b[32:32+t],b[32+t:32+t+d]

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--reference',type=Path,required=True,help='retail .j64 or retail .zip provided by user')
 ap.add_argument('--sdk',type=Path,required=True,help='supplied extracted Jaguar SDK root')
 ap.add_argument('--output',type=Path,default=ROOT/'Club_Drive_source_hybrid.j64')
 ap.add_argument('--accept-other-rom',action='store_true',help='allow an exact-layout reference other than known retail hash')
 ap.add_argument('--allow-edited-world-gpu',action='store_true',help='EXPERIMENTAL: embed changed GPU kernels inside compressed worlds, only same-size binaries')
 ap.add_argument('--allow-edited-main-gpu',action='store_true',help='EXPERIMENTAL: allow same-sized compiled GPU kernels to overwrite verified retail addresses')
 ap.add_argument('--skip-reauthentication',action='store_true',help='Keep retail RSA header despite payload edits (emulator-only development, not hardware safe)')
 args=ap.parse_args()
 sdk=sdk_assembler(args.sdk.resolve())
 if args.reference.suffix.lower()=='.zip':
  with zipfile.ZipFile(args.reference) as z:
   files=[n for n in z.namelist() if n.lower().endswith('.j64')]
   if len(files)!=1:raise ValueError('reference zip needs exactly one .j64')
   retail=z.read(files[0])
 else:retail=args.reference.read_bytes()
 if len(retail)!=2097152:raise ValueError('Reference must be exactly 2 MiB')
 digest=hashlib.sha256(retail).hexdigest()
 if digest!=ORIGINAL_SHA and not args.accept_other_rom:
  raise ValueError('Reference ROM SHA-256 differs from documented retail: '+digest)
 if retail[0x400:0x408]!=bytes.fromhex('0404040400802000'):
  raise ValueError('Unexpected cartridge marker/entry: not recognized Club Drive header')
 if retail[0:0x400]==bytes(0x400):raise ValueError('Encrypted cartridge header missing')
 image=bytearray(retail)
 out=ROOT/'build'; (out/'obj').mkdir(exist_ok=True,parents=True);(out/'gpu').mkdir(exist_ok=True,parents=True)
 # Refresh exact original byte-layout inputs from the supplied editable PNGs.
 from build.graphics_roundtrip import compile_png
 compile_png()
 compiled=[]
 for m in MODULES:
  obj=out/'obj'/f'{m}.o'
  ok=run([sdk,'-dCOMPAT=0','-fb','-u','-icompat_include','-o',str(obj),('ART.S' if m.lower()=='art' else m.lower()+'.s')],out/f'assemble_{m}.log')
  if not ok:raise RuntimeError(f'68000 module {m} failed; see {out}/assemble_{m}.log')
  compiled.append({'module':m,'bytes':obj.stat().st_size})
 # Source layout at ROM 0xE5690 was found independently by matching font bytes.
 off=retail.find(FONT)
 if off!=0xE5690:raise ValueError(f'PLAYDATA font offset unexpected: {off:#x}')
 text,data=section(out/'obj/playdata.o');code=text+data
 if len(code)!=19424:raise ValueError('PLAYDATA generated size changed; cannot safely re-layout retail ROM')
 image[off:off+len(code)]=code
 overlays=[{'source':'playdata.s + 4 PNG graphics','rom_start':off,'rom_end':off+len(code), 'bytes':len(code),'changed':sum(a!=b for a,b in zip(code,retail[off:off+len(code)]))}]
 gpu_report=[]
 for m in GPU:
  src=ROOT/(m.lower()+'.gas')
  if not src.exists():continue
  bin=out/'gpu'/(m+'.bin')
  log=out/f'assemble_gpu_{m}.log'
  if bin.exists():bin.unlink()
  ok=run([sdk,'-dCOMPAT=0','-mtom','-fr','-icompat_include','-o',str(bin),str(src)],log)
  assembler_source=str(src.relative_to(ROOT))
  if not ok:
   # Original 1994 GASM handles register aliases, includes and macro syntax
   # differently from RMAC. Translate only the unsupported language features;
   # then assemble the original logic unchanged rather than stubbing it out.
   if m=='gpunzip':
    macro_script=ROOT/'build/inline_gpu_macros.py'
    if not run([sys.executable,str(macro_script)],out/'macro_gpunzip.log'):
     raise RuntimeError('Failed expanding GPU decompression macros')
    translated=out/'compat_gpu/gpunzip.gas'
   else:
    from build.legacy_gpu_compat import Port
    translated=Port().run(m)
   assembler_source=str(translated.relative_to(ROOT))
   ok=run([sdk,'-dCOMPAT=0','-mtom','-fr','-icompat_include','-o',str(bin),str(translated)],log)
  row={'module':m,'assembled':ok,'asm_source':assembler_source}
  if ok:
   b=bin.read_bytes();row['size']=len(b)
   if len(b)>4096:raise ValueError(f'{m} GPU code exceeds Tom GPU RAM capacity')
   if m in EXACT_GPU:
    dest,size=EXACT_GPU[m]
    if len(b)!=size:raise ValueError(f'GPU code {m} changed size; cannot safely overlay')
    old=retail[dest:dest+size]
    diff=sum(a!=c for a,c in zip(b,old))
    if diff and not args.allow_edited_main_gpu:
     raise ValueError(f'{m} GPU differs from retail at expected fixed offset; use --allow-edited-main-gpu only after testing')
    image[dest:dest+size]=b
    overlays.append({'source':src.name,'rom_start':dest,'rom_end':dest+size,'bytes':size,'changed':diff})
   row['embedded_in_retail']=retail.find(b)>=0
  else:row['errors_log']=f'build/assemble_gpu_{m}.log'
  gpu_report.append(row)
 from build.recovered_resources import apply as rebuild_resources
 resource_patches=rebuild_resources(retail,image,out/'gpu',allow_edited_gpu=args.allow_edited_world_gpu)
 from build.recover_audio import apply as rebuild_audio,generate_asm,OUT as AUDIO_DIR,BANK_START,BANK_END
 audio_patches=rebuild_audio(retail,image)
 sound_asm=generate_asm(json.loads((AUDIO_DIR/'audio_index.json').read_text()))
 sound_obj=out/'obj/sounds_reconstructed.o'
 if not run([sdk,'-fb','-u','-o',str(sound_obj),str(sound_asm)],out/'assemble_sounds_reconstructed.log'):
  raise RuntimeError('Unable to assemble all 49 recovered audio resources')
 generated_text,generated_data=section(sound_obj)
 if generated_text+generated_data!=image[BANK_START:BANK_END]:
  raise RuntimeError('Compiled SOUND_RECONSTRUCTED.S does not exactly match reconstructed sound bank')
 from build.compile_tail_graphics import apply as rebuild_raw_images
 raw_image_patches=rebuild_raw_images(retail,image)
 if image[:0x2000]!=retail[:0x2000]:raise AssertionError('Boot header modified before signing')
 if image[0x2000:0x2020]!=retail[0x2000:0x2020]:raise AssertionError('Game code entry altered')
 header_status='retail header unchanged; ROM payload unchanged'
 payload_edits=image[0x2000:]!=retail[0x2000:]
 if payload_edits:
  if args.skip_reauthentication:
   header_status='WARNING: edited payload with old retail header (authentication not regenerated)'
  else:
   jagcrypt=args.sdk.resolve()/'tools/bin/jagcrypt'
   if not jagcrypt.is_file():raise RuntimeError('SDK jagcrypt needed to reauthenticate modified image')
   # Jaguar cartridge signature covers the payload. SDK jagcrypt regenerates
   # the MD5/RSA first-stage header for the new image. It accepts preexisting
   # authenticated cartridge headers and outputs a one-chip *.U1 image.
   with tempfile.TemporaryDirectory(prefix='club_reauth_') as work:
    source=Path(work)/'club.rom';source.write_bytes(image)
    p=subprocess.run([str(jagcrypt),'-u',source.name],cwd=work,stdout=subprocess.PIPE,
                     stderr=subprocess.STDOUT,text=True,timeout=120)
    (out/'jagcrypt.log').write_text(p.stdout)
    result=Path(work)/'club.U1'
    if p.returncode!=0 or not result.is_file():raise RuntimeError('jagcrypt failed: '+p.stdout)
    authenticated=result.read_bytes()
    if len(authenticated)!=len(image) or authenticated[0x2000:]!=image[0x2000:]:
     raise RuntimeError('Reauthentication changed payload or cartridge size')
    if authenticated[0x400:0x408]!=retail[0x400:0x408]:
     raise RuntimeError('Reauthentication altered Jaguar marker or entry')
    if authenticated[:0x400]==image[:0x400]:
     raise RuntimeError('Expected different encrypted authentication header after ROM modification')
    image=bytearray(authenticated)
    header_status='SDK jagcrypt -u regenerated encrypted MD5/RSA header for modified payload'

 args.output.parent.mkdir(exist_ok=True,parents=True)
 args.output.write_bytes(image)
 differences=sum(a!=b for a,b in zip(image,retail))
 report={
 'build_kind':'BOOTABLE RETAIL-DEPENDENT HYBRID (NOT full independent source rebuild)',
 'reference_sha256':digest,'output_sha256':hashlib.sha256(image).hexdigest(),
 'cartridge_size':len(image),'cartridge_entry':hex(int.from_bytes(image[0x404:0x408],'big')),
 'encrypted_boot_block':header_status,
 'main_68000_modules_compiled':len(compiled),'modules':compiled,
 'gpu_module_results':gpu_report,'safe_source_overlays':overlays,
 'bytes_changed_from_reference':differences,'payload_modified':payload_edits,
 'reconstructed_resource_count':22,'resource_modifications':resource_patches,
 'recovered_audio_count':49,'audio_modifications':audio_patches,
 'recovered_cryprompt_pngs':2,'raw_tail_image_modifications':raw_image_patches,
 'compiled_audio_bank':{'object':'build/obj/sounds_reconstructed.o','rom_start':hex(BANK_START),
   'rom_end':hex(BANK_END),'bytes':BANK_END-BANK_START,'assembled_exactly':True},
 'retail_fallback_bytes':len(image)-sum(x['bytes'] for x in overlays),
 'notes':['Unresolved worlds/sounds/renderer mean executable and assets outside overlays come from retail ROM.',
          'An unchanged output has the original retail SHA by design, not because the full game linked from source.',
          'Editing PNGs and re-running rebuild changes the PLAYDATA region without moving other sections.',
          'Seven GPU programs verified at original addresses are overlaid without changing retail data.',
          'Four world-local GPU programs were matched exactly inside decompressed world resources.',
          'Any editable resource change is recompressed only if it fits the original fixed ROM slot.',
          'The 42 raw F16 samples and 7 music scores are exact retail recoveries, replaceable in-place if lengths remain constant.',
          'On payload edits, SDK jagcrypt -u recalculates encrypted header; only emulator boot has been verified, not physical retail Jaguar hardware.']}
 (out/'hybrid_index.json').write_text(json.dumps(report,indent=2)+'\n')
 print(f"{args.output}: {len(image)} bytes, {differences} differences from retail")
 print(f"cartridge authentication: {header_status}; entry 0x{int.from_bytes(image[0x404:0x408],'big'):06X}")
 print(f"{len(compiled)} CPU objects; {sum(x['assembled'] for x in gpu_report)}/{len(gpu_report)} GPU programs assembled")
 print(f'49 audio assets compiled to an exact {BANK_END-BANK_START:,}-byte sound bank; {len(audio_patches)} modified audio assets')
 print('Manifest:',out/'hybrid_index.json')

if __name__=='__main__':main()
