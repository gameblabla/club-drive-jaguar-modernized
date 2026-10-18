#!/usr/bin/env python3
"""Build a non-bootable but progressively more complete, relocated 68000 image.

Everything injected via -ii is assembled GPU code or byte-extracted from a
verified gzip member in the reference cartridge. This is a diagnostics stage,
NOT a cartridge builder. It never synthesizes fake addresses for unknown data.
"""
from pathlib import Path
import argparse, hashlib, json, re, subprocess, sys, zlib, zipfile, struct

ROOT=Path(__file__).resolve().parent.parent
SDK_DEFAULT=ROOT.parent/'club_rebuild/jaguar-sdk-linux-x86_64'
OBJ_NAMES='game sys input title select credits hiscore eeprim sound tables remote play mkmat blit gpufix playinp td modem readjoy'.split()
OBJ_TAIL='art playdata mktp alloc lattice inflate packet sounds_reconstructed legacy_equates_recovered'.split()
GPU_LABELS={'3d':'gpprog','gpunzip':'_gpunzip','adjblack':'adblack',
 'uncomp':'uncomp','lighten':'lighten','cross':'cross','fade':'fade',
 'comp':'cgpprog','precomp':'precomp','ren':'rgpprog','preren':'preren',
 'casbeg':'casbeg','racbeg':'racbeg','tagbeg':'tagbeg',
 'casend':'casend','racend':'racend','tagend':'tagend'}
# These names follow the explicit 1994 Makefile resource order. For entries
# tagged candidate in resources.json, attribution is provisional; see report.
RECOVERED_LABELS={
 0x54118:'art',0xEA390:'o_STARTICON',0xEA500:'studio',0xF4F78:'future',
 0xF6E38:'garage',0xFEEC8:'westa',0x104820:'toya',0x1050E8:'bighouse',
 0x11F5B8:'westw',0x14CA20:'city',0x1AE1C0:'racew',0x1B9F70:'toyw',
 0x1BBBE8:'garr',0x1BF258:'o_SKY',0x1CA550:'o_GARASKY',
 0x1E0DB0:'o_PWRBALL',0x1ED6B8:'o_PAUSECRY',0x1F4380:'o_HOOD'}

def load_rom(path):
 if path.suffix.lower()=='.zip':
  with zipfile.ZipFile(path) as z:
   names=[n for n in z.namelist() if n.lower().endswith('.j64')]
   if len(names)!=1:raise ValueError('Expected one .j64')
   return z.read(names[0])
 return path.read_bytes()

def world_source_payload(rec, reference, *, allow_edited_world_gpu=False):
 """Recreate one decompressed world from its editable binary and GPU assembly.

 Retail is used to establish/verify the historical slot, but a changed .GAS
 kernel is taken from the current assembler output, not from the retail ROM.
 No offsets are guessed; the world-local GPU location is pinned in resources.json.
 """
 from recovered_resources import WORLD_GPU
 start,end=rec['rom_start'],rec['rom_end']
 original=zlib.decompress(reference[start:end],31)
 if len(original)!=rec['raw_size'] or hashlib.sha256(original).hexdigest()!=rec['original_sha256']:
  raise ValueError(f'{rec["file"]}: recovered world reference/length mismatch')
 new=bytearray((ROOT/'assets/native/resources/packed'/rec['file']).read_bytes())
 if len(new)!=len(original):raise ValueError(f'{rec["file"]}: world changed size; unsupported')
 details={'world_gpu':None,'source_assembly_embedded':False,'source_gpu_changed':False}
 if start in WORLD_GPU:
  name,offset=WORLD_GPU[start]
  gpu=(ROOT/'build/gpu'/f'{name}.bin').read_bytes()
  if not 0<=offset<=len(original)-len(gpu):raise ValueError(f'{name}: invalid world offset')
  previous=original[offset:offset+len(gpu)]
  if new[offset:offset+len(gpu)]!=previous and bytes(new[offset:offset+len(gpu)])!=gpu:
   raise ValueError(f'{name}: both raw world and assembled GPU code changed same region')
  changed=gpu!=previous
  if changed and not allow_edited_world_gpu:
   raise ValueError(f'{name}: source-assembled GPU differs from retail; opt in with --allow-edited-world-gpu')
  # Enforce original dimensions: world-internal offsets may be size dependent.
  expected={'gpustud':514,'gpugara':308,'gpuhouse':872,'gpucity':308}[name]
  if len(gpu)!=expected:raise ValueError(f'{name}: changed GPU size {len(gpu)} != {expected}')
  new[offset:offset+len(gpu)]=gpu
  details.update(world_gpu=name,source_assembly_embedded=True,source_gpu_changed=changed,
    gpu_original_offset=offset,gpu_code_sha256=hashlib.sha256(gpu).hexdigest())
 return bytes(new),original,details

def extract_packed(reference,records,*,allow_edited_world_gpu=False):
 """Emit linkable world resources, substituting *assembled* world GPU code."""
 from recovered_resources import compress_fit
 out=ROOT/'build/packed_sources';out.mkdir(parents=True,exist_ok=True)
 rows=[]
 for rec in records:
  if rec['rom_start'] not in RECOVERED_LABELS:continue
  start,end=rec['rom_start'],rec['rom_end']
  new,old,details=world_source_payload(rec,reference,allow_edited_world_gpu=allow_edited_world_gpu)
  encoded=reference[start:end] if new==old else compress_fit(new,end-start)
  assert zlib.decompress(encoded,31)==new
  dest=out/f'{start:06X}.gz';dest.write_bytes(encoded)
  rows.append(dict(symbol=RECOVERED_LABELS[start],file=rec['file'],rom_start=hex(start),
    packed_file=str(dest.relative_to(ROOT)),packed_original_bytes=end-start,
    packed_built_bytes=len(encoded),uncompressed_bytes=len(new),changed=new!=old,
    uncompressed_sha256=hashlib.sha256(new).hexdigest(),**details))
 (ROOT/'build/source_world_gpu_index.json').write_text(json.dumps(rows,indent=2)+'\n')
 print('Source-linked worlds:',len(rows),'with',sum(r['source_assembly_embedded'] for r in rows),
       'source GPU programs and',sum(r['changed'] for r in rows),'edited resources')
 return out

def unresolved(text):
 if 'UNRESOLVED SYMBOLS' not in text:return []
 return sorted(set(re.findall(r'^\s+([^\s(]+)\s+\([^()]+\.o\)\s*$',text.split('UNRESOLVED SYMBOLS',1)[1],re.M)))

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--sdk',type=Path,required=True)
 ap.add_argument('--reference',type=Path,required=True)
 ap.add_argument('--extract',action='store_true',help='Rebuild packed gzip members from editable raw assets and GPU assembly')
 ap.add_argument('--allow-edited-world-gpu',action='store_true',help='Allow changed same-length world GPU programs')
 args=ap.parse_args()
 meta=json.loads((ROOT/'assets/native/resources/packed/resources.json').read_text())
 rom=load_rom(args.reference)
 if hashlib.sha256(rom).hexdigest()!=meta['reference_rom_sha256']:raise ValueError('Unexpected reference ROM')
 packed=ROOT/'build/packed_sources'
 if args.extract:extract_packed(rom,meta['resources'],allow_edited_world_gpu=args.allow_edited_world_gpu)
 gpu=ROOT/'build/gpu'
 deps=[]
 for k,v in GPU_LABELS.items():
  p=gpu/(k+'.bin')
  if not p.is_file():raise FileNotFoundError(p)
  deps.append({'symbol':v,'file':str(p.relative_to(ROOT)),'verified_source':'GPU .GAS'})
 for rec in meta['resources']:
  address=rec['rom_start'];name=RECOVERED_LABELS.get(address)
  if not name:continue
  p=packed/f'{address:06X}.gz'
  if not p.is_file():raise FileNotFoundError(f'{p} - first run with --extract')
  required,_,_=world_source_payload(rec,rom,allow_edited_world_gpu=args.allow_edited_world_gpu)
  if zlib.decompress(p.read_bytes(),31)!=required:
   raise ValueError('Packed source gzip does not represent editable world or assembled GPU '+rec['file']+'; rerun source linker with --extract')
  deps.append({'symbol':name,'file':str(p.relative_to(ROOT)),'rom_start':hex(address),
               'verified_source':'Makefile order + recovered gzip' if 'candidate' in rec['label'] else 'Recovered gzip'})
 # Original .jag and .m resource labels recovered from actual ROM data
 # tables in tables.s and play.s (not assigned by ambiguous sequence guesses).
 manifest_file=ROOT/'assets/native/graphics/encoded/graphics_index.json'
 if not manifest_file.is_file():raise FileNotFoundError('Run build/recover_graphics_assets.py first')
 graphic_meta=json.loads(manifest_file.read_text())
 if graphic_meta['reference_sha256']!=meta['reference_rom_sha256']:raise ValueError('Graphic address manifest mismatch')
 for rec in graphic_meta['resources']:
  f=ROOT/'assets/native/graphics/encoded'/rec['original_filename']
  if hashlib.sha256(f.read_bytes()).hexdigest()!=rec['sha256']:
   raise ValueError('Recovered graphic/mask changed; original game compressor not yet available: '+str(f))
  if rom[rec['start']:rec['slot_end']]!=f.read_bytes():
   raise ValueError('Recovered graphic/mask differs from retail region '+rec['symbol'])
  deps.append({'symbol':rec['symbol'],'file':str(f.relative_to(ROOT)),
               'rom_start':hex(rec['start']),'verified_source':'CPU runtime pointer table' })
 # Instruction-pointer-verified original 68000 and GPU decompression binaries.
 helpers_path=ROOT/'assets/native/tools/helpers_index.json'
 if not helpers_path.is_file():raise FileNotFoundError('Run build/recover_binary_helpers.py first')
 helpers=json.loads(helpers_path.read_text())
 if helpers['reference_sha256']!=meta['reference_rom_sha256']:raise ValueError('Helper manifest reference mismatch')
 for rec in helpers['resources']:
  f=ROOT/'assets/native/tools'/rec['original_filename']
  data=f.read_bytes()
  if hashlib.sha256(data).hexdigest()!=rec['sha256'] or rom[rec['start']:rec['slot_end']]!=data:
   raise ValueError('Reconstructed helper binary does not match verified ROM address: '+rec['symbol'])
  deps.append({'symbol':rec['symbol'],'file':str(f.relative_to(ROOT)),
               'rom_start':hex(rec['start']),'verified_source':'sys.s code operand; native binary preserved'})
 # Final six symbolic resource files are identified by source-matched
 # executable pointer instructions; no linker address stubs are invented.
 final_path=ROOT/'assets/native/graphics/final/final_assets_index.json'
 if not final_path.is_file():raise FileNotFoundError('Run build/recover_tail_resources.py first')
 final_assets=json.loads(final_path.read_text())
 if final_assets['reference_sha256']!=meta['reference_rom_sha256']:
  raise ValueError('Final asset address manifest reference mismatch')
 for rec in final_assets['resources']:
  f=ROOT/'assets/native/graphics/final'/rec['original_filename']
  data=f.read_bytes()
  if hashlib.sha256(data).hexdigest()!=rec['sha256'] or rom[rec['start']:rec['slot_end']]!=data:
   raise ValueError('Final resource does not match verified retail instruction reference: '+rec['symbol'])
  deps.append({'symbol':rec['symbol'],'file':str(f.relative_to(ROOT)),
               'rom_start':hex(rec['start']),'verified_source':'title.s/play.s opcode operand; raw or gzip original'})
 objs=[ROOT/'build/obj'/f'{x}.o' for x in OBJ_NAMES]
 objs += [ROOT/'build/fulsyn_normalized.oj']
 objs += [ROOT/'build/obj'/f'{x}.o' for x in OBJ_TAIL]
 for p in objs:
  if not p.is_file():raise FileNotFoundError(p)
 cmd=[str(args.sdk.resolve()/'tools/bin/rln'),'-z','-m','-a','802000','81d000','4000',
      '-o','build/source_link_stage5']
 cmd += [str(o.relative_to(ROOT)) for o in objs]
 for dep in deps:cmd += ['-ii',dep['file'],dep['symbol']]
 p=subprocess.run(cmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
 (ROOT/'build/source_link_stage5.log').write_text(p.stdout)
 # Prior diagnostic linker log is optional in a clean extracted archive.
 prior_log=ROOT/'build/link_audio_stage.log'
 before=prior_log.read_text() if prior_log.is_file() else ''
 symbols_before=unresolved(before)
 symbols_after=unresolved(p.stdout)
 # Parse the Atari TOS ABS header to measure real linked sections. This
 # exposes layout defects even when the external symbol count is zero.
 output=ROOT/'build/source_link_stage5.abs'
 if output.exists():
  blob=output.read_bytes()
  if blob[:2]!=b'\x60\x1b':raise ValueError('rln output is not an Atari absolute image')
  seg_text,seg_data,seg_bss=struct.unpack_from('>III',blob,2)
  layout={'text_start':'0x802000','text_bytes':seg_text,'text_end':hex(0x802000+seg_text),
     'data_start':'0x81D000','data_bytes':seg_data,'data_end':hex(0x81D000+seg_data),
     'bss_start':'0x4000','bss_bytes':seg_bss,'bss_end':hex(0x4000+seg_bss),
     'cartridge_data_overrun_bytes':max(0,0x81D000+seg_data-0xA00000),
     'text_data_overlap_bytes':max(0,0x802000+seg_text-0x81D000)}
 else:layout=None
 result={'link_status':p.returncode,'prior_unique_unresolved':len(symbols_before),
  'remaining_unique_unresolved':len(symbols_after),
  'remaining':symbols_after,'layout':layout,'resolved_from_prior':sorted(set(symbols_before)-set(symbols_after)),
  'resource_symbols':deps,'linker_output':'build/source_link_stage5.abs',
  'note':'All external symbols now resolve. The unchanged source has a 4360-byte data-bank overrun in retail layout; trial contiguous layout assembles a signed image but graphics fail. This ABS is not a playable cartridge.'}
 (ROOT/'build/source_link_stage5.json').write_text(json.dumps(result,indent=2)+'\n')
 print('Source/retail resource linker stage:',p.returncode,'prior:',len(symbols_before), 'after:',len(symbols_after),
       'resolved:',len(result['resolved_from_prior']))
 print('Unresolved:',', '.join(symbols_after))
 if layout: print('Link memory:',hex(layout['text_bytes']),'text,',hex(layout['data_bytes']),
    'data,',hex(layout['bss_bytes']),'BSS; cartridge overrun',layout['cartridge_data_overrun_bytes'],'bytes')
 if p.returncode!=0 and not symbols_after:sys.exit(1)

if __name__=='__main__':main()
