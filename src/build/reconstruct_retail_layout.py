#!/usr/bin/env python3
"""Recover the exact 1994 GPU-container and late 68000 code layout.

The GPU opcodes come ONLY from freshly assembled .GAS inputs under build/gpu_link.
The late helper block is explicitly ROM-disassembled binary code, with machine
words retained as source directives and decoded M68k instructions as comments.
No source-vs-reference equivalence is assumed outside the verified window.
"""
import argparse, collections, hashlib, json, re, subprocess, struct
from pathlib import Path
from link_recovered_stage import load_rom
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/native/rom/source'
START=0x13574
C_START=0x1ae08
END=0x1d000
GPU_ORDER=('3d','casbeg','tagbeg','racbeg','comp','ren','casend','tagend','racend','gpunzip','precomp','preren')
LABELS={'3d':'gpprog','casbeg':'casbeg','tagbeg':'tagbeg','racbeg':'racbeg','comp':'cgpprog','ren':'rgpprog','casend':'casend','tagend':'tagend','racend':'racend','gpunzip':'_gpunzip','precomp':'precomp','preren':'preren'}
def align(p):return (p+7)&~7
def cmds(disassembler, blob, address):
    if not disassembler:return {}
    path=OUT/'retail_c68000_reference.bin';path.write_bytes(blob)
    p=subprocess.run([str(disassembler),'-D','-b','binary','-m','m68k',f'--adjust-vma=0x{address+0x800000:x}',str(path)],capture_output=True,text=True)
    if p.returncode:raise RuntimeError(p.stderr[-1200:])
    instruction={}
    # GNU objdump 68k reports instruction bytes as groups of 16 bit words.
    for line in p.stdout.splitlines():
        m=re.match(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{4}\s+)+)\s+(.+)$',line,re.I)
        if m:
            off=int(m.group(1),16)-0x800000
            if address<=off<END:instruction[off]=m.group(3).strip()
    return instruction

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--reference',type=Path,required=True)
    ap.add_argument('--sdk',type=Path,required=True)
    a=ap.parse_args()
    rom=load_rom(a.reference)
    assert len(rom)==0x200000
    OUT.mkdir(exist_ok=True)
    listing=[f'; Original Jaguar ROM cartridge file offsets 0x{START:05X}..0x{END:05X}',
      '; retail_overlay verified fixed-address release layout (not used in the source-linked ROM yet).',
      '; Every GPU program is included from compiled .GAS source, never from retail GPU opcode dumps.',
      '; The helper block is 68000 CODE DISASSEMBLED FROM RETAIL, preserved as exact',
      '; machine words with decoded instruction comments, pending symbolic relinking.',
      ' .text','club_release_code_begin::']
    current=START
    def add_literal(bs,why):
        nonlocal current
        if bs:
            listing.append(f' ; 0x{current:06X}: {why}')
            for n in range(0,len(bs),16):
                chunk=bs[n:n+16]
                if len(chunk)%2:raise AssertionError('Odd word literal')
                listing.append(' dc.w '+','.join('$%04X'%int.from_bytes(chunk[i:i+2],'big') for i in range(0,len(chunk),2)))
            current+=len(bs)
    add_literal(rom[START:0x13578],'Original 68000 NOPs at first GPU boundary')
    manifests=[]
    for name in GPU_ORDER:
        asm=ROOT/'build/gpu_link'/f'{name}.bin'
        data=asm.read_bytes()
        if data!=rom[current:current+len(data)]:raise AssertionError(f'{name} assembled bytes disagree with retail at 0x{current:X}')
        listing.extend((f' ; 0x{current:06X} GPU {name.upper()} -- generated from {name.upper()}.GAS',
                         f'club_{LABELS[name]}::',f' incbin "build/gpu_link/{name}.bin"'))
        manifests.append(dict(gpu=name,retail_offset=current,bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
        current+=len(data)
        pad=rom[current:align(current)]
        add_literal(pad,f'Original 1994 linker padding after {name} (not assumed zero)')
    if current!=C_START:raise AssertionError(f'GPU layout unexpectedly ends at 0x{current:x}')
    op=cmds(a.sdk/'tools/bin/m68k-aout-objdump',rom[C_START:END],C_START)
    listing.extend((f'; First C/68000 helper instruction at ROM 0x{C_START:06X}',
                    '; Machine words reconstructed from retail. Decoded mnemonics are explanatory.',
                    '; Absolute call and data addresses are still literal retail addresses.',
                    'club_recovered_cpu_begin::'))
    # One machine-code word per line makes individual instructions discoverable
    # and keeps the byte-exact code directly assembleable by RMAC.
    for addr in range(C_START,END,2):
        word=struct.unpack_from('>H',rom,addr)[0]
        comment=op.get(addr,'')
        comment=re.sub(r'[\r\n;]',' ',comment)
        listing.append(f' dc.w ${word:04X}'+(f' ; ROM 0x{addr:06X}: {comment}' if comment else ''))
    listing+=('club_release_code_end::','')
    src=OUT/'RETAIL_RELEASE_CODE.S';src.write_text('\n'.join(listing))
    expected=rom[START:END]
    (OUT/'retail_code_window.sha256').write_text(hashlib.sha256(expected).hexdigest()+'\n')
    rmac=a.sdk/'tools/bin/rmac';rln=a.sdk/'tools/bin/rln'
    obj=OUT/'retail_release_code.o'
    p=subprocess.run([str(rmac),'-fb','-u','-o',str(obj),str(src)],cwd=ROOT,capture_output=True,text=True)
    if p.returncode:raise RuntimeError(f'RMAC failed: {p.stdout}\n{p.stderr}')
    output=OUT/'retail_release_code'
    p=subprocess.run([str(rln),'-z','-a',f'{0x800000+START:x}','0','0','-o',str(output),str(obj)],cwd=ROOT,capture_output=True,text=True)
    if p.returncode:raise RuntimeError(f'RLN failed: {p.stdout}\n{p.stderr}')
    absf=output.with_suffix('.abs').read_bytes()
    if absf[:2]!=b'\x60\x1b':raise AssertionError('Bad linked ABS header')
    text_sz,data_sz,_=struct.unpack_from('>III',absf,2)
    actual=absf[36:36+text_sz]
    if data_sz or len(actual)<len(expected) or actual[:len(expected)]!=expected or any(actual[len(expected):]):
        loc=next((i for i,(x,y) in enumerate(zip(actual,expected)) if x!=y),None)
        raise AssertionError(f'rebuilt 68000+GPU window mismatch text={text_sz} data={data_sz} first={loc}')
    actual=actual[:len(expected)] # RLN rounds section size up to 8-byte phrase, adding four trailing zeros.
    out=OUT/'release_layout_verified.bin';out.write_bytes(actual)
    summary={'rom_offset_start':hex(START),'rom_offset_end':hex(END),
       'rom_load_start':hex(0x800000+START),'assembled_bytes':len(actual),
       'exact_matching_bytes':sum(a==b for a,b in zip(actual,expected)),
       'sha256':hashlib.sha256(actual).hexdigest(),
       'gpu_source_containers':manifests,
       '68000_rom_disassembled_bytes':END-C_START,
       'instruction_annotations':len(op),
       'caveat':'Separate release-layout block; not yet linked into the bootable ROM; 68000 instructions retained as dc.w and comments. Internal absolute addresses need symbolic relocation before moving code.'}
    (OUT/'index.json').write_text(json.dumps(summary,indent=2)+'\n')
    print('MATCH: release GPU+68000 block',len(actual),'of',len(expected),'at',hex(START),'through',hex(END))
    print('GPU programs from source',len(manifests),'retail C68000 disassembly words',(END-C_START)//2)
if __name__=='__main__':main()
