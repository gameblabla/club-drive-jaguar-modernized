#!/usr/bin/env python3
"""Fix legacy Atari TOS .OJ symbol flags for absolute Jaguar DSP addresses.

The shipped FULSYN.OJ is not corrupt: old Atari ALN used $A000 to denote
exported DSP-absolute memory symbols. Modern RMAC/RLN mistakenly treats
those symbols as relocatable BSS, causing a >180 MB RAM allocation.

The executable machine code and symbol values are NOT changed; only the
12 legacy exported absolute address flags change from $A000 to $8000.
FULSYN_S is an actual relocatable code label (flag $A200) and stays such.
"""
from pathlib import Path
import struct, hashlib, json
ROOT=Path(__file__).resolve().parent.parent
SOURCE=ROOT/'assets/native/toolchain/FULSYN.OJ'; OUT=ROOT/'build/fulsyn_normalized.oj'

def main():
 data=bytearray(SOURCE.read_bytes())
 if data[:2]!=b'\x60\x1a':raise ValueError('Expected original 68000 TOS object')
 text,seg_data,seg_bss,syms=struct.unpack_from('>IIII',data,2)
 if (text,seg_data,seg_bss,syms)!=(2964,0,0,3584):raise ValueError('Unexpected source object layout')
 off=28+text+seg_data
 if off+syms>len(data) or syms%14:raise ValueError('Truncated legacy table')
 edits=[]
 for i in range(off,off+syms,14):
  name=data[i:i+8].split(b'\x00')[0].decode('ascii')
  flag=struct.unpack_from('>H',data,i+8)[0]
  addr=struct.unpack_from('>I',data,i+10)[0]
  if flag==0xa000:
   if addr<0xF10000 or addr>=0xF20000:raise ValueError(f'{name} not a Jaguar DSP absolute address: {addr:#x}')
   struct.pack_into('>H',data,i+8,0x8000)
   edits.append({'symbol':name,'address':hex(addr),'old_flag':'0xA000','new_flag':'0x8000'})
  elif flag not in (0x8000,0xa200):raise ValueError(f'Unknown Atari flag {flag:#x} for {name}')
 if len(edits)!=12:raise ValueError(f'Expected 12 legacy absolute DSP symbols; saw {len(edits)}')
 OUT.write_bytes(data)
 (ROOT/'build/fulsyn_normalization.json').write_text(json.dumps({'original_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
 'normalized_sha256':hashlib.sha256(data).hexdigest(),'symbols':edits,'code_section_identical':True},indent=2)+'\n')
 print('Normalized',len(edits),'legacy absolute Jaguar DSP symbols; preserved original 2964 bytes of executable code')
if __name__=='__main__':main()
