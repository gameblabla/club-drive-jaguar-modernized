#!/usr/bin/env python3
"""Fixed-offset release-code overlay onto the provided retail cartridge.

IMPORTANT: A verified hybrid, NOT an independently source-linked ROM.
Only the window 0x13574..0x1d000 is inserted from generated source assembly.
The rest of the retail ROM is retained. Authenticate edits with jagcrypt.
"""
from pathlib import Path
import argparse,hashlib,json,struct,subprocess,tempfile
from link_recovered_stage import load_rom,ROOT
START=0x13574;END=0x1d000

def run(a, cwd=ROOT):
 p=subprocess.run([str(x) for x in a],cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
 if p.returncode:raise RuntimeError(p.stdout[-2400:])
 return p.stdout

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--reference',type=Path,required=True)
 ap.add_argument('--sdk',type=Path,required=True)
 ap.add_argument('--output',type=Path,default=ROOT/'Club_Drive_retail_overlay.j64')
 ap.add_argument('--allow-edits',action='store_true',help='sign edited code; never consider the result retail-identical')
 a=ap.parse_args()
 sdk=a.sdk.resolve();ref=load_rom(a.reference)
 if len(ref)!=0x200000:raise RuntimeError('Expected 2 MiB retail ROM')
 src=ROOT/'assets/native/rom/source/RETAIL_RELEASE_CODE.S'
 obj=ROOT/'assets/native/rom/source/retail_overlay_overlay.o'
 run([sdk/'tools/bin/rmac','-fb','-u','-o',obj,src])
 name=ROOT/'assets/native/rom/source/retail_overlay_overlay'
 run([sdk/'tools/bin/rln','-z','-a','813574','0','0','-o',name,obj])
 absb=name.with_suffix('.abs').read_bytes()
 t,dat,bs=struct.unpack_from('>III',absb,2)
 window=absb[36:36+END-START]
 if dat or bs or t<END-START or t>END-START+7:raise RuntimeError('Unexpected source release block length')
 if t>END-START and any(absb[36+END-START:36+t]):raise RuntimeError('Unexpected text padding')
 changed=sum(a!=b for a,b in zip(window,ref[START:END]))
 if changed and not a.allow_edits:
  raise RuntimeError(f'{changed} source bytes differ from retail; rerun with --allow-edits to reauthenticate')
 new=bytearray(ref);new[START:END]=window
 if changed:
  with tempfile.TemporaryDirectory() as tmp:
   p=Path(tmp)/'overlay.rom';p.write_bytes(new)
   run([sdk/'tools/bin/jagcrypt','-u','overlay.rom'],cwd=tmp)
   b=(Path(tmp)/'overlay.U1').read_bytes()
  if len(b)!=0x200000 or b[START:]!=new[START:] or b[0x400:0x408]!=b'\x04\x04\x04\x04\x00\x80\x20\x00':
   raise RuntimeError('Signing modified cartridge payload unexpectedly')
 else:b=bytes(new)
 a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_bytes(b)
 report=dict(status='RETAIL-HYBRID / fixed-offset overlay',retail_sha256=hashlib.sha256(ref).hexdigest(),
   new_rom_sha256=hashlib.sha256(b).hexdigest(),source_overlay_start=hex(START),source_overlay_end=hex(END),
   source_overlay_bytes=END-START,changed_bytes_in_source_window=changed,
   changed_bytes_in_authentication=sum(a!=bb for a,bb in zip(b[:0x2000],ref[:0x2000])),
   retail_identical=b==ref,
   caveat='Only a 39,564-byte window comes from rebuilt GPU/disassembled 68000 source. All other ROM bytes are retained from retail.')
 (ROOT/'build/retail_overlay.json').write_text(json.dumps(report,indent=2)+'\n')
 print('PASS hybrid overlay: source window',END-START,'changed',changed,'ROM hash',report['new_rom_sha256'])
if __name__=='__main__':main()
