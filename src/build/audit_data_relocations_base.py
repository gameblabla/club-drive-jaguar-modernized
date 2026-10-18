#!/usr/bin/env python3
"""Classify remaining retail/rebuild executable differences without patching code.

The lookup-table proof is tied to the surviving original inflate.s and
INFLATE.C, not to guessed semantics from disassembly.  It verifies the table
bytes at both linked addresses and reports all referring instruction slots.
This is an AUDIT, not a machine-code relocation/overlay tool.
"""
import argparse, collections, hashlib, json
from pathlib import Path
from link_recovered_stage import load_rom

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

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--reference', type=Path, required=True)
    ap.add_argument('--source', type=Path, required=True)
    ap.add_argument('--json', type=Path, default=Path('build/fallback_link_relocation_audit.json'))
    args = ap.parse_args()
    r, s = load_rom(args.reference), load_rom(args.source)
    if len(r) != len(s) or len(s) != 0x200000: raise ValueError('Both cartridges must be 2 MiB')
    table_reports = []
    for name, ra, sa, length in TABLES:
        rb, sb = ra-0x800000, sa-0x800000
        original, rebuilt = r[rb:rb+length], s[sb:sb+length]
        if original != rebuilt: raise ValueError(f'{name}: source data differs from original values')
        table_reports.append(dict(symbol=name,retail_runtime_address=f'0x{ra:06X}',
          source_runtime_address=f'0x{sa:06X}',length=length,
          source_is_original=True,sha256=hashlib.sha256(original).hexdigest()))
    ranges = extract_runs(r, s, 0x2000, 0x1D000)
    matching_relocations, other_pointers, non_pointer = [], [], []
    for begin, end in ranges:
        if end-begin != 3 or begin%2 != 1:
            non_pointer.append(dict(file_offset=f'0x{begin:06X}',length=end-begin,
              retail=r[begin:end].hex(),rebuilt=s[begin:end].hex()))
            continue
        ofs = begin-1
        src_val = int.from_bytes(s[ofs:ofs+4], 'big')
        ref_val = int.from_bytes(r[ofs:ofs+4], 'big')
        if not (0x800000 <= src_val < 0xA00000 and 0x800000 <= ref_val < 0xA00000):
            non_pointer.append(dict(file_offset=f'0x{begin:06X}',length=3,
                retail=r[begin:end].hex(),rebuilt=s[begin:end].hex()))
            continue
        src_off, ref_off = src_val-0x800000, ref_val-0x800000
        longest = 0
        while longest < 128 and s[src_off+longest] == r[ref_off+longest]:
            longest += 1
        entry = dict(file_offset=f'0x{ofs:06X}',source_target=f'0x{src_val:08X}',
                     retail_target=f'0x{ref_val:08X}',verified_matching_prefix=longest)
        (matching_relocations if longest >= 16 else other_pointers).append(entry)
    helper_sites = [x for x in matching_relocations
      if any(int(x['source_target'],16)==t[2] and int(x['retail_target'],16)==t[1] for t in TABLES)]
    if len(helper_sites) != 10: raise ValueError(f'Expected ten recovered Huffman-table references, got {len(helper_sites)}')
    report = dict(source_sha256=hashlib.sha256(s).hexdigest(),reference_sha256=hashlib.sha256(r).hexdigest(),
       executable_region='0x2000-0x1CFFF',executable_bytes=0x1B000,
       exact_bytes=sum(x==y for x,y in zip(r[0x2000:0x1D000],s[0x2000:0x1D000])),
       differing_byte_runs=len(ranges),
       verified_address_relocations=len(matching_relocations),
       verified_address_relocation_differing_bytes=3*len(matching_relocations),
       other_pointer_differences=other_pointers,
       residual_non_address_differences=non_pointer,
       deflate_tables=table_reports,
       deflate_table_code_references=helper_sites,
       all_verified_resource_addresses=matching_relocations,
       note='No addresses or instructions are rewritten; a 128-byte matching prefix is NOT proof of complete asset identity. Ten INFLATE references correspond to full, length-checked source tables.')
    out=args.json;out.parent.mkdir(exist_ok=True,parents=True)
    out.write_text(json.dumps(report,indent=2)+'\n')
    print(f'Exact CPU/GPU executable bytes: {report["exact_bytes"]}/{report["executable_bytes"]}')
    print(f'Verified data relocation operands: {len(matching_relocations)} (each three differing bytes)')
    print(f'Full-source original C DEFLATE tables: {len(table_reports)}, helper references: {len(helper_sites)}')
    print(f'Other pointer diffs: {len(other_pointers)}; non-pointer byte runs: {len(non_pointer)}')
    print(f'Audit saved to {out}')

if __name__=='__main__': main()
