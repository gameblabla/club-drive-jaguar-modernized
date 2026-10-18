#!/usr/bin/env python3
"""Reassemble CLUB Drive's release-layout CPU against retail data addresses.

This is an explicitly RETAIL-DEPENDENT alternate build: all data past $1D000
and the initial boot template come from the reference cartridge, while the
whole $2000-$1CFFF executable is reassembled and all its 141 relocations
are checked against the original layout. An optional equal-length CPU source
edit can be copied across and reauthenticated after preserving the old
verified baseline. This does not independently regenerate all Jaguar data.
"""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
from link_recovered_stage import ROOT,load_rom

START,END=0x2000,0x1D000

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--reference',type=Path,required=True)
    p.add_argument('--source',type=Path,required=True)
    p.add_argument('--audit',type=Path,default=ROOT/'build/retail_link_relocation_audit.json')
    p.add_argument('--sdk',type=Path,required=True)
    p.add_argument('--output',type=Path,default=ROOT/'Club_Drive_retail_slot.j64')
    p.add_argument('--allow-edited-cpu',action='store_true',help='Opt in to modified fixed-length 68000 instructions')
    p.add_argument('--baseline-source',type=Path,help='Unmodified retail_link source ROM whose SHA matches the relocation audit')
    a=p.parse_args()
    original,source=load_rom(a.reference),load_rom(a.source)
    baseline=load_rom(a.baseline_source) if a.baseline_source else source
    audit=json.loads(a.audit.read_text())
    if len(original)!=0x200000 or len(source)!=len(original) or len(baseline)!=len(original):
        raise ValueError('Expected 2 MiB Jaguar cartridges')
    if hashlib.sha256(baseline).hexdigest()!=audit['source_sha256']:
        raise ValueError('Relocation audit does not correspond to this source-built baseline')
    if hashlib.sha256(original).hexdigest()!=audit['reference_sha256']:
        raise ValueError('Wrong retail reference cartridge')
    if audit['unexplained_byte_count']!=0 or audit['unclassified_differences']:
        raise ValueError('Unexplained executable differences; unsafe retail-slot relocation')
    addresses=(audit['long_form_relocations']+audit['low_word_only_relocations']+
               audit['internal_structure_relocations'])
    if len(addresses)!=141:raise ValueError('Unexpected original resource relocation count')
    pointer_sites=set()
    for row in addresses:
        offset=int(row['file_offset'],16)
        if offset<START or offset+4>END:raise ValueError('Pointer outside original program')
        if any(i in pointer_sites for i in range(offset,offset+4)):
            raise ValueError('Overlapping relocation slots')
        pointer_sites.update(range(offset,offset+4))
        if int.from_bytes(baseline[offset:offset+4],'big')!=int(row['source_target'],16):
            raise ValueError(f'Stale source relocation at {offset:#x}')
        if int.from_bytes(original[offset:offset+4],'big')!=int(row['retail_target'],16):
            raise ValueError(f'Stale retail relocation at {offset:#x}')
    all_changes=[i for i,(x,y) in enumerate(zip(source,baseline)) if x!=y]
    changed=[i for i in all_changes if START<=i<END]
    if all_changes:
        if not a.allow_edited_cpu or not a.baseline_source:
            raise ValueError('CPU edits require --allow-edited-cpu and --baseline-source')
        # A CPU edit makes jagcrypt regenerate its encrypted header, so header
        # differences are expected. The linked audio/graphic data and all
        # 141 original-address relocation operands must stay untouched.
        if len(changed)>128 or any(i>=END or i in pointer_sites for i in all_changes):
            raise ValueError('Source edit changes the data section, verified pointer operands or >128 CPU bytes')
    output=bytearray(original)
    output[START:END]=source[START:END]
    for row in addresses:
        pos=int(row['file_offset'],16)
        source_value=int(row['source_target'],16)
        original_value=int(row['retail_target'],16)
        if int.from_bytes(output[pos:pos+4],'big')!=source_value:
            raise ValueError('Modified source executable changed a verified pointer')
        output[pos:pos+4]=original_value.to_bytes(4,'big')
    # The only permitted differences must be the deliberately edited CPU
    # instruction bytes. This proves original executable placement is exact.
    residual=[i for i in range(START,END) if output[i]!=original[i]]
    if residual!=changed:
        raise ValueError('Unexpected opcode or label change after retail-slot relocation')
    if changed:
        with tempfile.TemporaryDirectory(prefix='club15_signed_') as tmp:
            temp=Path(tmp)
            (temp/'Release.rom').write_bytes(output)
            subprocess.run([str(a.sdk.resolve()/'tools/bin/jagcrypt'),'-u','Release.rom'],
                           cwd=temp,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=120)
            result=(temp/'Release.U1').read_bytes()
        if result[START:]!=output[START:] or len(result)!=len(output):
            raise ValueError('Authentication tool changed executable or resource data')
    else:
        result=bytes(output)
    target=a.output if a.output.is_absolute() else ROOT/a.output
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(result)
    summary=dict(mode='retail-dependent verified address layout',
      output_sha256=hashlib.sha256(result).hexdigest(),
      baseline_source_sha256=hashlib.sha256(baseline).hexdigest(),
      authenticated_new_payload=bool(changed),edited_cpu_bytes=len(changed),
      cpu_from_source_bytes=END-START,pointer_operands_verified=len(addresses),
      matched_original_sha256=(result==original),
      original_data_retained_from_retail=True)
    (ROOT/'build/retail_link_retail_slot_summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    print('RETAIL_LINK RETAIL-SLOT: all',END-START,'executable bytes assembled from source')
    print('Address relocation operands verified:',len(addresses))
    print('Edited instruction bytes:',len(changed),'re-authenticated:',bool(changed))
    print('Byte-identical to retail:',result==original)
    print('SHA256',summary['output_sha256'],target)

if __name__=='__main__':main()
