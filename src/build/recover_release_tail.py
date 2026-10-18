#!/usr/bin/env python3
"""Document a proven later retail 68000 region as reassemblable machine words.

This is not the original source or a C decompilation. It preserves opcodes and
operands of the ROM exactly, while adding best-effort instruction decoding to
help future semantic/source-level recovery. Decoding can treat embedded data as
instructions. The output is explicitly labeled as a transcription.
"""
import argparse,hashlib,re,subprocess,zipfile
from pathlib import Path
START=0x1C814
END=0x1D000
ROOT=Path(__file__).resolve().parent.parent

def load(path):
    if path.suffix.lower()=='.zip':
        with zipfile.ZipFile(path) as z:
            members=[x for x in z.namelist() if x.lower().endswith(('.j64','.rom'))]
            if len(members)!=1:raise ValueError('Need exactly one .j64 in reference ZIP')
            return z.read(members[0])
    return path.read_bytes()

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--reference',type=Path,required=True)
    ap.add_argument('--objdump',type=Path,required=True)
    ap.add_argument('--output',type=Path,default=ROOT/'assets/native/rom/source/RELEASE_LATE_CPU.S')
    a=ap.parse_args();rom=load(a.reference)
    if len(rom)!=0x200000:raise ValueError('Not a Jaguar 2 MiB retail reference')
    section=rom[START:END]
    decoder={}
    import tempfile
    with tempfile.TemporaryDirectory() as temp:
        binfile=Path(temp)/'late.bin';binfile.write_bytes(section)
        p=subprocess.run([str(a.objdump),'-D','-b','binary','-m','m68k',f'--adjust-vma={START+0x800000:#x}',str(binfile)],capture_output=True,text=True,check=True)
        for line in p.stdout.splitlines():
            m=re.match(r'^\s*([0-9a-f]+):\s*([0-9a-f ]+)\s+(.+)',line)
            if m:
                pos=int(m.group(1),16)-0x800000
                if START<=pos<END:decoder[pos]=m.group(3).strip().replace(';',',')
    lines=['; ============================================================================',
    '; CLUB DRIVE - RETAIL-RECOVERED LATE 68000 CODE AND CONSTANTS (bootstrap_link)',
    '; ============================================================================',
    '; Provenance: supplied final Club Drive cartridge, byte span',
    f';   ROM file offsets ${START:06X} through ${END-1:06X} inclusive.',
    ';   SHA-256 of exact region: '+hashlib.sha256(section).hexdigest(),
    '; This code/embedded data is NOT present in the surviving 1994 source.',
    '; The hex words are faithfully transcribed as ASSEMBLER SOURCE and',
    '; each decoded mnemonic is machine-generated guidance, NOT Atari comments.',
    '; Some data might have been decoded as instructions; do not infer function',
    '; boundaries from these comments. Pointers remain fixed to retail layout.',
    '; Inputs/outputs: unknown for unlabeled routines, require flow tracing.',
    '; Source editors: replacing a dc.w sequence with an equivalent instruction',
    '; is supported, but the slot MUST retain its original size until the',
    '; historical relocation model is fully recovered.',
    '; This region must follow packet.s and precede the original data segment.',
    '; ============================================================================',
    '\t.text',
    'club_late_code_begin::']
    for offset in range(START,END,2):
        word=int.from_bytes(rom[offset:offset+2],'big')
        decoded=decoder.get(offset)
        if offset in (0x1C814,0x1C818,0x1C99E,0x1CB00):
            lines.append(f'; ---- ROM ${offset:06X}: recovered boundary (semantic role unverified) ----')
        note=decoded if decoded else 'extension word or undecoded data'
        lines.append(f'\tdc.w\t${word:04X}\t; ${offset:06X}  {note}')
    lines.extend(['club_late_code_end::','; EOF: no original compiler source was invented.'])
    output=a.output if a.output.is_absolute() else ROOT/a.output
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text('\n'.join(lines)+'\n')
    print(f'Recovered {len(section)} bytes / {len(section)//2} annotated words:',output)
if __name__=='__main__':main()
