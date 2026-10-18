#!/usr/bin/env python3
"""Insert source-grounded 1994-style comments into preserved assembler modules.

Documentation is based on the original corresponding .C files in the source
archive.  It does not modify the machine instructions or reconstruct original
compiler directives.  The added text is openly labeled as 2026 annotations.
"""
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
HEAD='; ---- release_overlay source-recovery notes (cross-referenced to original C) -----'
ANNOTATIONS={
'mktp.s':{
 '_alloc_it':('MAKE TRANSFORMED MODEL DATA / MKTP.C',
     'Entry: 8(A6) -> struct bndheader; returns D0=1 success, 0 failure.',
     'Allocate transformed vectors, colour, edges, dividers and collision polygons.',
     'When the model has no rotation matrix, reference its source points.',
     'Original C function: alloc_it; original gcc2/mit2mot instruction order retained.'),
 '_free_bnd':('FREE MODEL TRANSFORMS / MKTP.C',
     'Entry: 8(A6) -> old bndheader, possibly NULL; result: void.',
     'Walk bnd_list; decrement use_count; free transformed arrays on final use.',
     'Preserve source aliasing semantics for shared boundary geometry.'),
 '_use_bnd':('ACTIVATE REPLACEMENT BOUNDARY / MKTP.C',
     'Entry: 8(A6) -> newbnd, 12(A6) -> oldbnd.',
     'Update boundary-use bookkeeping and construct transform buffers as required.',
     'See the original use_bnd() C routine for exact error and lifetime rules.')},
'alloc.s':{
 '_alloc':('GENERAL MEMORY ALLOCATION / ALLOC.C',
     'Entry: 8(A6) = number of requested bytes; D0 = payload address or NULL.',
     'Eight-byte HEADER-based free list, split from tail when a block is larger.',
     'May call morecore to acquire more Jaguar RAM; writes allocation magic.'),
 '_morecore':('EXTEND THE FREE LIST / ALLOC.C',
     'Entry: 8(A6) = minimum HEADER units; return free-list pointer or NULL.',
     'Round to NALLOC units, obtain new RAM with sbrk, insert via free.'),
 '_free':('RELEASE ALLOCATED MEMORY / ALLOC.C',
     'Entry: 8(A6) = payload pointer; NULL is a no-op.',
     'Validate HEADER magic, insert into address-ordered free list and coalesce.'),
 '_sbrk':('HEAP BUMP ALLOCATOR / ALLOC.C',
     'Entry: 8(A6) = byte count; D0 = previous heap cursor or NULL.',
     'Keep heap phrase-aligned and below memavlbl (top page reserved).'),
 '_init_alloc':('INITIALIZE JAGUAR RAM ALLOCATOR / ALLOC.C',
     'Clear allocator state and set the top-of-heap limit to 2 MiB minus 4 KiB.')},
'lattice.s':{
 '_malloc':('LATTICE COMPATIBILITY MALLOC',
     'Allocation entry exposed to the original C helper/runtime.'),
 '_memzero':('ZERO BUFFER', 'General-purpose 68000 memory-zeroing helper.'),
 '_memcpy':('COPY MEMORY', 'Copy byte sequence between memory ranges; inspect original calling convention.'),
 '_bcopy':('COPY MEMORY (BSD CONVENTION)', 'Compatibility helper for byte-range copying.'),
 '__mulsi3':('SIGNED LONG MULTIPLICATION', 'Compiler support function for 32-bit signed multiplication.'),
 '__divsi3':('SIGNED LONG DIVISION', 'Compiler support function for 32-bit signed division.'),
 '__modsi3':('SIGNED LONG REMAINDER', 'Compiler support function for 32-bit signed remainder.')},
'inflate.s':{
 '_mask_bits':('DEFLATE BIT MASKS / INFLATE.C','17 powers-of-two-minus-one lookup entries; this is DATA, not a function.'),
 '_huft_build':('CONSTRUCT HUFFMAN DECODING TABLES / INFLATE.C',
    'Build code-length lookup tables used by the DEFLATE decoder.'),
 '_huft_free':('FREE HUFFMAN TABLES / INFLATE.C','Release the table allocations made by huft_build.'),
 '_flush':('FLUSH INFLATION OUTPUT / INFLATE.C','Write decompressed bytes to the output window / destination.'),
 '_inf_codes':('DECODE HUFFMAN LITERALS AND LENGTHS / INFLATE.C',
    'Decode the active literal/length and distance tables.'),
 '_inf_stored':('DECOMPRESS AN UNCOMPRESSED BLOCK / INFLATE.C',
    'Handle DEFLATE stored blocks without Huffman codes.'),
 '_inf_fixed':('DECOMPRESS FIXED-HUFFMAN BLOCK / INFLATE.C','Use the DEFLATE predefined trees.'),
 '_inf_dynamic':('DECOMPRESS DYNAMIC-HUFFMAN BLOCK / INFLATE.C',
    'Read code-length trees from compressed input and decode the block.'),
 '_inf_block':('DEFLATE BLOCK DRIVER / INFLATE.C',
    'Dispatch block types, track last-block flag and input bit buffer.'),
 '_inflate':('DEFLATE STREAM ENTRY / INFLATE.C',
    'Entry to original Mark Adler inflate, modified for Club Drive Jaguar.',
    'Original C file credits Eric R. Smith for memory-to-memory/GPU changes.')},
'packet.s':{
 '_chksum':('MODEM PACKET CHECKSUM / PACKET.C',
    'Calculate a checksum using type and three 16-bit packet data words.'),
 '_recpacket':('RECEIVE REMOTE PLAYER PACKET / PACKET.C',
    'Interpret received packet fields and update remote game state.'),
 '_sendpacket':('SEND GAME STATE PACKET / PACKET.C',
    'Form a packet from local state and pass it to the serial transmitter.'),
 '_initpackets':('INITIALIZE PACKET HANDLING / PACKET.C',
    'Initialize packet handler state and counters.')}
}

def run():
  changed=0
  for file,functions in ANNOTATIONS.items():
    path=ROOT/file
    data=path.read_text(encoding='latin-1')
    for label,lines in functions.items():
      pat=re.compile(r'(?m)^'+re.escape(label)+r':\s*$')
      match=pat.search(data)
      if not match: continue  # the compiler sometimes emits alias labels.
      before=data[max(0,match.start()-600):match.start()]
      if ('; ---- '+label+' / RELEASE_OVERLAY') in before:continue
      commentary=['; ------------------------------------------------------------------',
       '; ---- '+label+' / RELEASE_OVERLAY RECOVERY ANNOTATION ----',
       '; '+lines[0]]+['; '+line for line in lines[1:]]+[
       '; NOTE: commentary added in release_overlay from surviving C source / build analysis.',
       ';       Original machine-code order and historical labels are unchanged.',
       '; ------------------------------------------------------------------']
      data=data[:match.start()]+'\n'.join(commentary)+'\n'+data[match.start():]
      changed+=1
    if HEAD not in data:
      pos=data.find('\n')+1
      data=data[:pos]+'\n'+HEAD+'\n; Function headings below were recovered from the surviving Atari .C files.\n'+data[pos:]
    path.write_text(data,encoding='latin-1')
  print('Added release_overlay original-source-grounded function annotations:',changed)
if __name__=='__main__':run()
