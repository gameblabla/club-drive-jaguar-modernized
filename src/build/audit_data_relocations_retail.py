#!/usr/bin/env python3
"""Classify remaining retail/rebuild executable differences without patching code.

The lookup-table proof is tied to the surviving original inflate.s and
INFLATE.C, not to guessed semantics from disassembly.  It verifies the table
bytes at both linked addresses and reports all referring instruction slots.
This is an AUDIT, not a machine-code relocation/overlay tool.
"""
import argparse, collections, hashlib, json, struct
from pathlib import Path
from link_recovered_stage import load_rom, ROOT

TABLES = [
    # Original inflate.s data block: names, retail address, rebuilt address,
    # byte length.  The arrays are 68000 big-endian 16-bit integer entries.
    ('_border', 0x8EA270, 0x821BE0, 38),
    ('_cplens', 0x8EA296, 0x821C06, 62),
    ('_cplext', 0x8EA2D4, 0x821C44, 62),
    ('_cpdist', 0x8EA312, 0x821C82, 60),
    ('_cpdext', 0x8EA34E, 0x821CBE, 60),
]

def extract_runs(a, b, start, end):
    runs, active = [], False
    for i in range(start, end):
        if a[i] != b[i]:
            if not active: at = i; active = True
        elif active: runs.append((at, i)); active = False
    if active: runs.append((at, end))
    return runs

def normalized_dehuff_equal(original, rebuilt, old=0x81D000, new=0x9F1268):
    """Prove relocated dehuff is equal after undoing 172 stored pointers.

    Atari's raw binary tree was linked for $81D000. The retail_link source builder
    moves it, and must relocate its internal words for Jaguar execution.
    This verifier does not change executable or resource bytes.
    """
    if len(original)!=1392 or len(rebuilt)!=1392: return False,0
    data=bytearray(rebuilt)
    adjusted=0
    for off in range(0,len(original)-3,4):
        value=struct.unpack_from('>I',original,off)[0]
        if old<=value<old+len(original):
            got=struct.unpack_from('>I',rebuilt,off)[0]
            if got != value + (new-old): return False,adjusted
            struct.pack_into('>I',data,off,value)
            adjusted+=1
    return adjusted==172 and data==original,adjusted

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--reference',type=Path,required=True)
    ap.add_argument('--source',type=Path,required=True)
    ap.add_argument('--json',type=Path,default=Path('build/retail_link_relocation_audit.json'))
    args=ap.parse_args()
    r,s=load_rom(args.reference),load_rom(args.source)
    if len(r)!=0x200000 or len(s)!=len(r):raise ValueError('Expected two 2MiB Jaguar ROMs')
    tables=[]
    for name,ra,sa,length in TABLES:
        original=r[ra-0x800000:ra-0x800000+length]
        rebuilt=s[sa-0x800000:sa-0x800000+length]
        if original!=rebuilt:raise ValueError(f'{name}: DEFLATE source table differs')
        tables.append(dict(symbol=name,retail_runtime_address=hex(ra),
            source_runtime_address=hex(sa),length=length,
            sha256=hashlib.sha256(original).hexdigest()))
    runs=extract_runs(r,s,0x2000,0x1d000)
    relocated,short,internal,unresolved=[],[],[],[]
    for begin,end in runs:
        length=end-begin
        # Atari 68000 big-endian MOVE.L #absolute uses a 4-byte field.
        # The high $00 byte still matches; the next three usually differ.
        if length==3 and begin%2==1:
            ofs=begin-1
            raddr=int.from_bytes(r[ofs:ofs+4],'big')
            saddr=int.from_bytes(s[ofs:ofs+4],'big')
            if not(0x800000<=raddr<0xa00000 and 0x800000<=saddr<0xa00000):
                unresolved.append(dict(offset=hex(begin),length=length,reason='not a ROM pointer'));continue
            ro,so=raddr-0x800000,saddr-0x800000
            matching=0
            while matching<128 and ro+matching<len(r) and so+matching<len(s) and r[ro+matching]==s[so+matching]:
                matching+=1
            item=dict(file_offset=hex(ofs),retail_target=hex(raddr),
                      source_target=hex(saddr),matching_prefix=matching,differing_bytes=3)
            if matching>=16:
                relocated.append(item)
            elif raddr==0x81d000 and saddr==0x9f1268:
                old=r[ro:ro+1392];new=s[so:so+1392]
                equal,count=normalized_dehuff_equal(old,new,raddr,saddr)
                if not equal:raise ValueError('dehuff relocated tree no longer matches retail after pointer normalization')
                item.update(verified_whole_binary_after_relocation=True,
                            relocated_pointer_words=count,binary_length=1392)
                internal.append(item)
            else:
                unresolved.append(dict(**item,reason='unproved ROM relocation'))
            continue
        # When a 24-bit address stays in the same 64KiB bank, only the lower
        # 16 bits change. These five slots are not opcode mutations.
        if length==2 and begin%2==0:
            ofs=begin-2
            if ofs<0 or r[ofs:begin]!=s[ofs:begin]:
                unresolved.append(dict(offset=hex(begin),length=length,reason='address high word differs'));continue
            raddr=int.from_bytes(r[ofs:ofs+4],'big')
            saddr=int.from_bytes(s[ofs:ofs+4],'big')
            if not(0x800000<=raddr<0xa00000 and 0x800000<=saddr<0xa00000):
                unresolved.append(dict(offset=hex(begin),length=length,reason='unverified 16-bit delta'));continue
            ro,so=raddr-0x800000,saddr-0x800000
            equal_prefix=r[ro:ro+32]==s[so:so+32]
            if not equal_prefix:
                unresolved.append(dict(offset=hex(begin),length=length,reason='referenced data differs'));continue
            short.append(dict(file_offset=hex(ofs),retail_target=hex(raddr),
                              source_target=hex(saddr),matching_prefix=32,differing_bytes=2))
            continue
        unresolved.append(dict(offset=hex(begin),length=length,
                               retail=r[begin:end].hex(),rebuilt=s[begin:end].hex(),
                               reason='non-address discrepancy'))
    helper_sites=[x for x in relocated if any(int(x['source_target'],16)==t[2] and
                  int(x['retail_target'],16)==t[1] for t in TABLES)]
    if len(helper_sites)!=10:raise ValueError('Expected all ten original inflate table operands')
    expected=sum(x!=y for x,y in zip(r[0x2000:0x1d000],s[0x2000:0x1d000]))
    proved=sum(x['differing_bytes'] for x in relocated+short+internal)
    if not unresolved and proved!=expected:raise ValueError('Address-only audit does not cover all differing bytes')
    report=dict(source_sha256=hashlib.sha256(s).hexdigest(),reference_sha256=hashlib.sha256(r).hexdigest(),
       executable_region='0x2000-0x1CFFF',executable_bytes=0x1b000,
       exact_bytes=0x1b000-expected,differing_bytes=expected,
       explained_address_bytes=proved,unexplained_byte_count=expected-proved,
       long_form_relocations=relocated,low_word_only_relocations=short,
       internal_structure_relocations=internal,
       unclassified_differences=unresolved,
       deflate_tables=tables,deflate_table_code_references=helper_sites,
       interpretation='Every remaining changed byte is part of a verified relocated cartridge-data address. The instruction bytes otherwise match at identical ROM offsets. The rest of the data section is NOT yet original-layout.')
    args.json.parent.mkdir(parents=True,exist_ok=True)
    args.json.write_text(json.dumps(report,indent=2)+'\n')
    print('Same-address executable bytes:',report['exact_bytes'],'/ 110592')
    print('Relocated address operands:',len(relocated),'3-byte +',len(short),'2-byte +',len(internal),'dehuff tree')
    print('Explained differing bytes:',proved,'/',expected,'unclassified',len(unresolved))
    print('DEFLATE tables verified:',len(tables),'full table operands:',len(helper_sites))
    print('Report:',args.json)
    if unresolved:raise RuntimeError('Source-to-retail differences remain unclassified')

if __name__=='__main__':main()
