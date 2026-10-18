#!/usr/bin/env python3
"""Prove the hood/game-over gzip mapping from ROM-executable operands, not guessed names."""
from pathlib import Path
from link_recovered_stage import load_rom
import struct,zlib,sys,json,hashlib
ROOT=Path(__file__).resolve().parent.parent
rom=load_rom(Path(sys.argv[1]))
# play.s: move.l #o_HOOD,_inptr and move.l #gameovr,_inptr.
# Known opcode contexts come directly from the 68000 retail binary.
items=[('o_HOOD',0xA7B8,0x1F4380,320*60*2),('gameovr',0xB124,0x1F4BB0,160*104*2)]
resources=json.loads((ROOT/'assets/native/resources/packed/resources.json').read_text())['resources']
byoff={x['rom_start']:x for x in resources}
final=json.loads((ROOT/'assets/native/graphics/final/final_assets_index.json').read_text())['resources']
final_by_symbol={x['symbol']:x for x in final}
from link_recovered_stage import RECOVERED_LABELS
for name,site,offset,expected_len in items:
 assert rom[site:site+2]==b'\x23\xfc'
 assert rom[site+6:site+10]==bytes.fromhex('0001d60e')
 assert struct.unpack_from('>I',rom,site+2)[0] == 0x800000+offset
 record=byoff[offset]
 raw=(ROOT/'assets/native/resources/packed'/record['file']).read_bytes()
 assert len(raw)==expected_len,(name,len(raw))
 assert zlib.decompress(rom[offset:record['rom_end']],31)==raw
 if name=='o_HOOD':assert RECOVERED_LABELS[offset]==name
 if name=='gameovr':
  record=final_by_symbol[name]
  assert record['start']==offset and record['slot_end']==byoff[offset]['rom_end']
  assert (ROOT/'assets/native/graphics/final'/record['original_filename']).read_bytes()==rom[offset:record['slot_end']]
 print(name,'retail pointer',hex(0x800000+offset),'uncompressed',expected_len,'B: VERIFIED')
