#!/usr/bin/env python3
"""Name confidently identified retail functions in the recovered code listing.

Labels are accepted ONLY if linked source and retail instructions agree for the
first 16 bytes at the same historical ROM address. These labels are for human
readability; machine words still assemble byte-for-byte. No guessed labels.
"""
from pathlib import Path
import json,re,argparse
from link_recovered_stage import ROOT,load_rom

FUNCTIONS={
 '_alloc_it':('MKTP.C','allocate transformed geometry and collision buffers'),
 '_free_bnd':('MKTP.C','release boundary transforms after reference counts fall to zero'),
 '_use_bnd':('MKTP.C','activate a boundary model and maintain shared-resource counts'),
 '_alloc':('ALLOC.C','allocate heap storage from a HEADER free list'),
 '_morecore':('ALLOC.C','extend the heap and return a free-list block'),
 '_free':('ALLOC.C','release storage and coalesce adjacent free-list blocks'),
 '_sbrk':('ALLOC.C','advance the Jaguar RAM heap cursor, reserving the top page'),
 '_init_alloc':('ALLOC.C','reset the Club Drive heap allocator')}

def run(reference):
  src=ROOT/'assets/native/rom/source/RETAIL_RELEASE_CODE.S'
  content=src.read_text()
  linked=(ROOT/'build/release_overlay_link.abs').read_bytes()[36:]
  retail=load_rom(reference)
  mapping=(ROOT/'build/release_overlay_link_final.log').read_text()
  mapped=[]
  for symbol,(file,meaning) in FUNCTIONS.items():
    m=re.search(r'\b'+re.escape(symbol)+r'\s+G\s+([0-9A-F]{8})\b',mapping)
    if not m:raise ValueError('Missing named source function: '+symbol)
    address=int(m.group(1),16)-0x800000
    if not 0x1ae08<=address<0x1d000:raise ValueError('Outside recovered helper window: '+symbol)
    if linked[address-0x2000:address-0x2000+16]!=retail[address:address+16]:
      raise ValueError('Name not verified at this location: '+symbol)
    mapped.append((symbol,address,file,meaning))
  for symbol,offset,file,meaning in mapped:
    # Only edit the first dc.w line at the start of a validated routine.
    pat=re.compile(r'(?m)^ dc\.w \$[A-F0-9]{4} ; ROM 0x'+f'{offset:06X}'+r':')
    found=pat.search(content)
    if not found:raise ValueError('Original retail annotation missing at '+hex(offset))
    if f'club_retail_{symbol[1:]}::' in content:continue
    comment='\n'.join([
      '; ---------------------------------------------------------------',
      f'; {symbol} / $80{offset:06X}  (identified by same-address opcode match)',
      f'; Surviving source: {file}',
      f'; Purpose: {meaning}.',
      '; NOTE: reconstructed label / explanation, NOT original Atari prose.',
      ';       The dc.w opcodes below are still recovered from retail ROM.',
      '; ---------------------------------------------------------------',
      f'club_retail_{symbol[1:]}::',''])
    content=content[:found.start()]+comment+content[found.start():]
  src.write_text(content)
  path=ROOT/'assets/native/rom/source/HELPER_SYMBOLS.md'
  path.write_text('# Recovered 68000 helper symbol map\n\n'
     'Symbols below are grounded in the surviving MKTP.C and ALLOC.C functions and **16 exact opening instruction bytes** at their retail addresses. '
     'The comments are reconstruction annotations, not verbatim historical comments.\n\n'
     '| Original symbol | ROM offset | Source | Purpose |\n|---|---:|---|---|\n'+
     ''.join(f'| `{name}` | `0x{addr:06X}` | `{file}` | {purpose} |\n' for name,addr,file,purpose in mapped)+
     '\nThe remaining late C helpers retain their original surviving .S sources. No unverified retail labels were assigned.\n')
  print('Named and commented source-verified retail helper functions:',len(mapped))

if __name__=='__main__':
  ap=argparse.ArgumentParser()
  ap.add_argument('--reference',type=Path,required=True)
  a=ap.parse_args()
  run(a.reference)
