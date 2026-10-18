#!/usr/bin/env python3
"""Recreate Atari 1994 GASM/ALN GPU program container (.bin) headers.

A .GAS assembled to raw RMAC -fr output is not a load_gpu-compatible
resource.  The 68000 loader expects [BE32 GPU origin][BE32 byte length]
followed by raw RISC instructions.  Fixed retail headers are verified against
code matches; all other destinations follow the source ORG directive.
"""
from pathlib import Path
import hashlib, json, struct, zipfile, argparse
ROOT=Path(__file__).resolve().parent.parent
G_RAM=0xF03000
ORIGINS={
 '3d':G_RAM,'gpunzip':G_RAM,'adjblack':0xF03F80,'uncomp':0xF03400,
 'lighten':0xF03800,'cross':G_RAM,'fade':0xF03800,
 'comp':G_RAM+0x38,'precomp':G_RAM+0x38,'ren':G_RAM+0x38,'preren':G_RAM+0x38,
 'casbeg':G_RAM+0x38,'racbeg':G_RAM+0x38,'tagbeg':G_RAM+0x38,
 'casend':G_RAM+0x38,'racend':G_RAM+0x38,'tagend':G_RAM+0x38,
}
RETAIL_HEADERS={
 'gpunzip':0x19A68, 'lighten':0x538B0, 'cross':0x53950, 'fade':0x53E98,
 'casbeg':0x135B0,'tagbeg':0x14038,'racbeg':0x14788,
 'casend':0x16E28,'tagend':0x17CA8,'racend':0x18BA8,
}
FALLBACK_DEFAULT=('gpunzip','lighten','cross','fade')
RETAIL_MATCH={
 '3d':0x13580,'adjblack':0x537E8,'uncomp':0x53838,
 'comp':0x15130,'ren':0x15F80,'precomp':0x19E38,'preren':0x1A8F0,
}

def make(reference: bytes, fallback=FALLBACK_DEFAULT):
 fallback=set(fallback)
 if fallback-set(RETAIL_HEADERS):raise ValueError(f"Missing retail header offsets for fallback modules {fallback-set(RETAIL_HEADERS)}")
 output=ROOT/'build/gpu_link';output.mkdir(parents=True,exist_ok=True)
 results=[]
 for name, origin in ORIGINS.items():
  source=ROOT/'build/gpu'/f'{name}.bin'; b=source.read_bytes()
  if len(b)>0x1000 or (origin+len(b))>0xF04000: raise ValueError(f'{name}: GPU local RAM overflow')
  header=struct.pack('>II',origin,len(b))
  retail_binary_used=name in fallback
  if retail_binary_used:
   rom_start=RETAIL_HEADERS[name]
   (retail_org,retail_size)=struct.unpack_from('>II',reference,rom_start)
   if retail_org!=origin or not 0<retail_size<=4096 or retail_org+retail_size>0xF04000:
    raise ValueError(f'{name}: implausible retail GPU header')
   header=reference[rom_start:rom_start+8]
   b=reference[rom_start+8:rom_start+8+retail_size]
   if len(b)!=retail_size:raise ValueError(f'{name}: truncated retail GPU program')
  if name in RETAIL_MATCH:

   address=RETAIL_MATCH[name]
   if reference[address:address+len(b)]!=b:raise ValueError(name+' no longer matches retail')
   if reference[address-8:address]!=header:raise ValueError(f'{name}: recovered retail header differs: {reference[address-8:address].hex()} expected {header.hex()}')
  dest=output/f'{name}.bin'; dest.write_bytes(header+b)
  results.append(dict(name=name,origin=hex(origin),code_bytes=len(b),container_bytes=len(b)+8,
         original_gpu_asm=source.relative_to(ROOT).as_posix(),container_file=dest.relative_to(ROOT).as_posix(),
         verified_retail_header=name in RETAIL_MATCH or retail_binary_used,
         content_origin='retail fallback (source-compatible reconstruction incomplete)' if retail_binary_used else 'assembled .GAS source',
         sha256=hashlib.sha256(header+b).hexdigest()))
 (output/'index.json').write_text(json.dumps(results,indent=2)+'\n')
 print('Wrote',len(results),'load_gpu-compatible GPU programs; retail fallbacks',sorted(fallback))
 return results

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('reference',type=Path)
 p.add_argument('--fallback',default=','.join(FALLBACK_DEFAULT),help='Comma-separated GPU programs requiring retail fallback; empty means none')
 args=p.parse_args()
 if args.reference.suffix.lower()=='.zip':
  with zipfile.ZipFile(args.reference) as z:
   fn=[n for n in z.namelist() if n.endswith('.j64')];assert len(fn)==1
   data=z.read(fn[0])
 else:data=args.reference.read_bytes()
 make(data,tuple(filter(None,args.fallback.split(','))))
