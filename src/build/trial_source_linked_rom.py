#!/usr/bin/env python3
"""EXPERIMENT: link Club Drive CPU+resource sources into a genuine Jaguar ROM.

This intentionally uses a distinct filename and does NOT replace the known
working retail-dependent hybrid. The preserved retail boot program is
reauthenticated for all changes by the user's SDK jagcrypt. A successful link
and valid signature do not establish correct gameplay; emulator must be used.
"""
from pathlib import Path
import argparse,struct,json,subprocess,tempfile,hashlib
from link_recovered_stage import OBJ_NAMES,OBJ_TAIL,load_rom
ROOT=Path(__file__).resolve().parent.parent

def run(cmd,*,out=None):
 p=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
 if out:out.write_text(p.stdout)
 if p.returncode:raise RuntimeError(f'{cmd[0]} failed: {p.stdout[-1800:]}')
 return p.stdout

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--sdk',type=Path,required=True)
 ap.add_argument('--reference',type=Path,required=True)
 ap.add_argument('--gpu-headers',action='store_true',help='use reconstructed 8-byte GPU load headers')
 ap.add_argument('--relocate-dehuff',action='store_true',help='two-pass link to fix 172 JPEG Huffman table pointers')
 ap.add_argument('--output',type=Path,default=ROOT/'build/source_linked_trial.j64')
 a=ap.parse_args();a.output=(ROOT/a.output).resolve() if not a.output.is_absolute() else a.output;sdk=a.sdk.resolve();old=json.loads((ROOT/'build/source_link_stage5.json').read_text())
 if old['remaining_unique_unresolved'] or old['link_status']:
  raise ValueError('Diagnostic source linker has outstanding failures')
 tsize=old['layout']['text_bytes']
 # The code ends at this 8-byte aligned cartridge address. Shift the code/data
 # boundary left from the historic $81D000 to recover ~5 KiB of padding which
 # is needed by current reconstructed link resources.
 data_addr=0x802000+tsize
 if data_addr%8:raise ValueError('Code size does not meet Jaguar phrase alignment')
 objects=[f'build/obj/{x}.o' for x in OBJ_NAMES]
 objects += ['build/fulsyn_normalized.oj']
 objects += [f'build/obj/{x}.o' for x in OBJ_TAIL]
 cmd=[str(sdk/'tools/bin/rln'),'-z','-m','-a','802000',f'{data_addr:X}','4000',
      '-o','build/source_link_trial'] + objects
 for dep in old['resource_symbols']:
  path=dep['file']
  if a.gpu_headers and dep['symbol'] in __import__('link_recovered_stage').GPU_LABELS.values():
   name=next(n for n,symbol in __import__('link_recovered_stage').GPU_LABELS.items() if symbol==dep['symbol'])
   path='build/gpu_link/'+name+'.bin'
  cmd.extend(['-ii',path,dep['symbol']])
 run(cmd,out=ROOT/'build/source_link_trial.log')
 if a.relocate_dehuff:
  import re
  from relocate_dehuff import relocate
  first_log=(ROOT/'build/source_link_trial.log').read_text()
  m=re.search(r'\bdehuff\s+G\s+([0-9A-Fa-f]{8})\b',first_log)
  if not m:raise RuntimeError('No dehuff absolute location in RLN map')
  table_origin=int(m.group(1),16)
  relocation=relocate(table_origin)
  dep_index=cmd.index('dehuff')
  if cmd[dep_index-2]!='-ii':raise AssertionError('Incorrect linker layout for dehuff')
  cmd[dep_index-1]='build/relocated_resources/dehuff.bin'
  run(cmd,out=ROOT/'build/source_link_trial.log')
  check_log=(ROOT/'build/source_link_trial.log').read_text()
  m2=re.search(r'\bdehuff\s+G\s+([0-9A-Fa-f]{8})\b',check_log)
  if not m2 or int(m2.group(1),16)!=table_origin:raise RuntimeError('Relink moved the dehuff resource')
 p=ROOT/'build/source_link_trial.abs';b=p.read_bytes()
 if b[:2]!=bytes.fromhex('601b'):raise ValueError('Not Atari ABS')
 t,d,bs=struct.unpack_from('>III',b,2)
 if (t,bs)!=(tsize,old['layout']['bss_bytes']):raise ValueError('Unexpected source link section size changes')
 start=0x2000
 end=start+t+d
 if end>0x200000:raise ValueError(f'Assembled game does not fit two-megabyte cartridge: overflow {end-0x200000} bytes')
 if 0x4000+bs>0x200000:raise ValueError('BSS does not fit 2MiB Jaguar RAM')
 oldrom=load_rom(a.reference)
 if len(oldrom)!=0x200000:raise ValueError('Reference must be 2 MiB')
 payload=b[36:36+t+d]
 if len(payload)!=t+d:raise ValueError('ABS text/data extraction length mismatch')
 image=bytearray(oldrom[:0x2000]+payload+bytes(0x200000-end))
 if image[0x400:0x408]!=bytes.fromhex('0404040400802000'):raise ValueError('Cartridge marker corrupted')
 with tempfile.TemporaryDirectory(prefix='club_trial_sign_') as td:
  infile=Path(td)/'trial.rom';infile.write_bytes(image)
  s=subprocess.run([str(sdk/'tools/bin/jagcrypt'),'-u','trial.rom'],cwd=td,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
  (ROOT/'build/source_link_trial_sign.log').write_text(s.stdout)
  candidate=Path(td)/'trial.U1'
  if s.returncode or not candidate.is_file():raise RuntimeError('jagcrypt failed: '+s.stdout)
  signed=candidate.read_bytes()
 if signed[0x2000:]!=image[0x2000:] or len(signed)!=0x200000:
  raise ValueError('Authentication unexpectedly modified executable section')
 a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_bytes(signed)
 report={'status':'UNVERIFIED experimental independent link; use emulator',
   'output':str(a.output.relative_to(ROOT)), 'output_sha256':hashlib.sha256(signed).hexdigest(),
   'source_executable_bytes':t,'source_data_bytes':d,'source_bss_bytes':bs,
   'cartridge_payload_end':hex(end),'cartridge_padding_bytes':0x200000-end,
   'resource_source_count':len(old['resource_symbols']),
   'encrypted_boot_block_regenerated':signed[:0x2000]!=oldrom[:0x2000],
   'gpu_container_headers':a.gpu_headers,'dehuff_internal_relocation':a.relocate_dehuff}
 (ROOT/'build/source_link_trial.json').write_text(json.dumps(report,indent=2)+'\n')
 print('EXPERIMENTAL source-linked signed .j64 created:',a.output,'bytes',len(signed), 'payload end',hex(end))
 print('Assembly:',t,'code,',d,'data,',bs,'RAM BSS. Emulation still required.')
if __name__=='__main__':main()
