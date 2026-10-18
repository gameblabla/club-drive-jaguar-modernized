#!/usr/bin/env python3
"""Reverse a subset of the missing Club Drive cartridge resource pipeline.

The 22 native gzip members in the authenticated retail ROM are extracted as
byte-perfect *uncompressed* source files. In-place recompression honours the
original space available, preserving linker addresses, the retail header and
other resources. The four identified world-local GPU kernels are regenerated
from compiled source and installed in the uncompressed worlds BEFORE packing.

This is not geometry conversion from original 3DS .ASC into .MDL; these blobs
are recovered binary resource sources until those tools are recreated.
"""
from pathlib import Path
import argparse, gzip, hashlib, json, struct, zlib, zipfile

BASE=Path(__file__).resolve().parent.parent
OUT=BASE/'assets/native/resources/packed'
META=OUT/'resources.json'
# Labels reconstructed from exact GPU matches and original MAKEFILE order;
# names with a '?' are plausible only, not verified IDs.
NAMES={
 0x32318:'auxiliary_image_0',0x54118:'art_archive',0xEA390:'start_icon_candidate',
 0xEA500:'studio',0xF4F78:'future_candidate',0xF6E38:'garage',
 0xFEEC8:'westa_candidate',0x104820:'toy_arena_candidate',
 0x1050E8:'bighouse',0x11F5B8:'west_world_candidate',0x14CA20:'city',
 0x1AE1C0:'race_world_candidate',0x1B9F70:'toyrace_candidate',
 0x1BBBE8:'garage_race_candidate',0x1BF258:'sky_cry16',
 0x1CA550:'garage_sky_cry16',0x1E0DB0:'misc_large_resource',
 0x1ED6B8:'pause_candidate',0x1F1BD8:'short_graphic_1',
 0x1F2260:'short_graphic_2',0x1F4380:'hood_cry16',
 0x1F4BB0:'gameover_cry16'
}
WORLD_GPU={
 0xEA500:('gpustud',13792),
 0xF6E38:('gpugara',19168),
 0x1050E8:('gpuhouse',131864),
 0x14CA20:('gpucity',705656)
}
SKY={0x1BF258:'sky_cry16',0x1CA550:'garage_sky_cry16'}

def sha(dat):return hashlib.sha256(dat).hexdigest()

def reference_data(path):
 if path.suffix.lower()=='.zip':
  with zipfile.ZipFile(path) as z:
   names=[n for n in z.namelist() if n.lower().endswith('.j64')]
   if len(names)!=1:raise ValueError('Need exactly one J64 in ZIP')
   return z.read(names[0])
 return path.read_bytes()

def inflate_member(rom,start):
 if rom[start:start+3]!=bytes.fromhex('1f8b08'):raise ValueError(f'Not gzip at {start:#x}')
 dec=zlib.decompressobj(31)
 data=dec.decompress(rom[start:]);data+=dec.flush()
 if not dec.eof:raise ValueError(f'Gzip not terminated at {start:#x}')
 consumed=len(rom)-start-len(dec.unused_data)
 return data,consumed

def export_resources(rom,overwrite=False):
 OUT.mkdir(exist_ok=True,parents=True)
 records=[]
 for start,name in sorted(NAMES.items()):
  raw,packed=inflate_member(rom,start)
  key=f'{start:06X}_{name}'
  filename=key+'.bin'
  dest=OUT/filename
  if not dest.exists() or overwrite:dest.write_bytes(raw)
  records.append({'rom_start':start,'rom_end':start+packed,
      'packed_capacity':packed,'raw_size':len(raw),
      'original_sha256':sha(raw),'file':filename,'label':name,
      'known_gpu':WORLD_GPU.get(start,[None,None])[0],
      'gpu_uncompressed_offset':WORLD_GPU.get(start,[None,None])[1]})
 META.write_text(json.dumps({'reference_rom_sha256':sha(rom),'resources':records},indent=2)+'\n')
 # Represent 16-bit CRY sky pixels with two lossless channels in RGB PNGs:
 # R = high CRY byte, G = low CRY byte, B = intensity preview.
 from PIL import Image
 for start,name in SKY.items():
  raw=(OUT/f'{start:06X}_{name}.bin').read_bytes()
  if len(raw)!=768*120*2:raise ValueError('Expected 768x120 CRY16 sky')
  png=OUT/(f'{start:06X}_{name}.png')
  if overwrite or not png.exists():
   im=Image.frombytes('RGB',(768,120),bytes(v for i in range(0,len(raw),2) for v in (raw[i],raw[i+1],raw[i+1])))
   im.save(png,optimize=True)
 print(f'Exported {len(records)} verified gzip assets, {sum(r["raw_size"] for r in records)} uncompressed bytes')
 return records

def compile_sky():
 from PIL import Image
 for start,name in SKY.items():
  png=OUT/f'{start:06X}_{name}.png'
  if not png.exists():continue
  im=Image.open(png)
  if im.size!=(768,120) or im.mode!='RGB':raise ValueError(f'{png}: must be 768x120 RGB')
  raw=im.tobytes()
  compiled=bytes(v for i in range(0,len(raw),3) for v in raw[i:i+2])
  (OUT/f'{start:06X}_{name}.bin').write_bytes(compiled)

def compress_fit(data,capacity):
 compressed=gzip.compress(data,compresslevel=9,mtime=0)
 if len(compressed)>capacity:
  try:
   import zopfli.gzip
   compressed=zopfli.gzip.compress(data,numiterations=10)
  except ImportError:pass
 if len(compressed)>capacity:raise ValueError(f'Compressed resource {len(compressed)} exceeds fixed slot {capacity}; cannot safely relocate it')
 if zlib.decompress(compressed,31)!=data:raise AssertionError('Roundtrip failed')
 return compressed

def apply(rom, image, gpu_dir, *, gpu_overrides=True, sky_pngs=True, allow_edited_gpu=False):
 if not META.exists():raise FileNotFoundError('Run recovered_resources.py export first')
 m=json.loads(META.read_text());records=m['resources']
 if sha(rom)!=m['reference_rom_sha256']:raise ValueError('Resource manifest reference SHA differs')
 if sky_pngs:compile_sky()
 patches=[]
 for rec in records:
  start,end=rec['rom_start'],rec['rom_end']
  old=rom[start:end]
  raw=zlib.decompress(old,31)
  if sha(raw)!=rec['original_sha256']:raise AssertionError('Stale manifest '+rec['file'])
  new=bytearray((OUT/rec['file']).read_bytes())
  if len(new)!=rec['raw_size']:raise ValueError('Changed raw resource size '+rec['file'])
  gpu=None
  if gpu_overrides and start in WORLD_GPU:
   gp_name,gp_offset=WORLD_GPU[start]
   compiled=(gpu_dir/(gp_name+'.bin')).read_bytes()
   expected_len={'gpustud':514,'gpugara':308,'gpuhouse':872,'gpucity':308}[gp_name]
   if len(compiled)!=expected_len:raise ValueError(f'World GPU {gp_name} changes binary size ({len(compiled)} vs {expected_len}); relocation needed')
   original_gpu=raw[gp_offset:gp_offset+expected_len]
   if original_gpu!=compiled and new[gp_offset:gp_offset+expected_len]!=original_gpu:
    raise ValueError('GPU source and raw resource both changed at '+rec['file'])
   if original_gpu!=compiled and not allow_edited_gpu:
    raise ValueError('New GPU differs from verified retail; use --allow-edited-world-gpu for experimental rebuild')
   new[gp_offset:gp_offset+expected_len]=compiled
   gpu={'name':gp_name,'source_bytes':len(compiled),'relative_offset':gp_offset,'matched_retail':original_gpu==compiled}
  if bytes(new)==raw:
   rec['rebuilt']=False;continue
  zipped=compress_fit(new,end-start)
  # Reuse remainder of the old slot as padding, never shift subsequent assets.
  image[start:end]=zipped+bytes(end-start-len(zipped))
  if zlib.decompress(image[start:end],31)!=new:raise AssertionError('Patching resource failed')
  patches.append({'file':rec['file'],'rom_start':start,'old_packed':end-start,'new_packed':len(zipped),'raw_bytes':len(new),'gpu':gpu})
 return patches

if __name__=='__main__':
 a=argparse.ArgumentParser(description=__doc__)
 a.add_argument('action',choices=['export','reexport','validate'])
 a.add_argument('--reference',required=True,type=Path)
 p=a.parse_args();rom=reference_data(p.reference)
 if p.action in ('export','reexport'):export_resources(rom,p.action=='reexport')
 else:
  meta=json.loads(META.read_text())
  assert meta['reference_rom_sha256']==sha(rom)
  for r in meta['resources']:
   raw,packed=inflate_member(rom,r['rom_start'])
   assert len(raw)==r['raw_size'] and packed==r['packed_capacity']
   assert sha(raw)==r['original_sha256']
  print('Verified',len(meta['resources']),'resource locations and checksums')
