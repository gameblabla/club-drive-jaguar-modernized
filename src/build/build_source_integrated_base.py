#!/usr/bin/env python3
"""Link editable Club Drive CPU sources with the original 1994 GPU order.

Unlike the retail_overlay hybrid overlay this replaces the ordinary CPU-linked cartridge.
Reference ROM is used only for preserved native resources / boot template and
binary verification; no retail 68000 instruction region is overlaid.
"""
import argparse,hashlib,json,re,struct,subprocess,tempfile
from pathlib import Path
from link_recovered_stage import ROOT,OBJ_NAMES,OBJ_TAIL,GPU_LABELS,load_rom
from integrate_release_gpu import construct,START,C_START
from relocate_dehuff import relocate
from rebuild_art import prepare as prepare_art

EARLY_KERNELS={'3d','casbeg','tagbeg','racbeg','comp','ren','casend','tagend','racend','gpunzip','precomp','preren'}

def run(cmd,path=None,cwd=ROOT,timeout=140):
    p=subprocess.run([str(x) for x in cmd],cwd=cwd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
    if path:Path(path).write_text(p.stdout)
    if p.returncode:raise RuntimeError(f'{cmd[0]}: return code {p.returncode}: {p.stdout[-2500:]}')
    return p.stdout

def link_cmd(sdk, data_base, target, manifest):
    main=[f'build/obj/{n}.o' for n in OBJ_NAMES]
    # The 1994 Makefile puts binary GPU containers before the late C helpers.
    # ART.S is reconstructed editable font/image source, and was NOT an OFILE
    # in the historical Makefile. Place it after those C functions; leaving it
    # before MKTP would displace all the original function entry points.
    late=[f'build/obj/{n}.o' for n in OBJ_TAIL]
    late.remove('build/obj/art.o')
    # ART.S is an independently compressed art.z resource in the retail Makefile; do not link its raw graphics into CPU text.
    # The art resource is already supplied by the recovered external asset manifest.
    objects=main+['build/fulsyn_normalized.oj','assets/native/rom/source/release_gpu.o']+late
    cmd=[sdk/'tools/bin/rln','-z','-m','-a','802000',f'{data_base:X}','4000','-o',target]+objects
    for rec in manifest['resource_symbols']:
        label=rec['symbol']
        if label in {GPU_LABELS[n] for n in EARLY_KERNELS}:continue
        resource=rec['file']
        if label in GPU_LABELS.values():
            n=next(n for n,v in GPU_LABELS.items() if v==label)
            resource=f'build/gpu_link/{n}.bin'
        if label=='art' and (ROOT/'build/source_generated/art.gz').exists():
            resource='build/source_generated/art.gz'
        if label=='dehuff' and (ROOT/'build/relocated_resources/dehuff.bin').exists():
            resource='build/relocated_resources/dehuff.bin'
        cmd.extend(['-ii',resource,label])
    return cmd

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--reference',required=True,type=Path)
    ap.add_argument('--sdk',required=True,type=Path)
    ap.add_argument('--output',default='Club_Drive_source_integrated.j64',type=Path)
    ap.add_argument('--allow-edited-retail-tail',action='store_true',help='Permit a same-size edit to recovered retail opcode source, while retaining linker addresses')
    a=ap.parse_args();sdk=a.sdk.resolve();ref=load_rom(a.reference)
    if len(ref)!=0x200000:raise RuntimeError('Expected 2 MiB reference cartridge')
    manifest=json.loads((ROOT/'build/source_link_stage5.json').read_text())
    if manifest['remaining_unique_unresolved']:raise RuntimeError('Existing source linker still has unresolved symbols')
    construct(a.reference,sdk)
    art_result=prepare_art(sdk)
    # This executable tail is transcribed from the later final ROM, because
    # the surviving packet.s ends immediately before it. Its words are now
    # maintained as commented, editable assembler source.
    run([sdk/'tools/bin/rmac','-fb','-u','-o',ROOT/'assets/native/rom/source/release_late_cpu.o',
         ROOT/'assets/native/rom/source/RELEASE_LATE_CPU.S'])
    # Normal linker pads the 1994 DSP module with four zero bytes.  The
    # historical Jaguar linker emitted two NOP instructions there instead.
    # Generate those instructions from readable assembly source, NOT the ROM.
    padding_obj=ROOT/'assets/native/rom/source/linker_nops.o'
    run([sdk/'tools/bin/rmac','-fb','-u','-o',padding_obj,
         ROOT/'assets/native/rom/source/LINKER_NOP_BASE.S'])
    padding=padding_obj.read_bytes()[32:36]
    if padding!=bytes.fromhex('4e714e71'):raise RuntimeError('Historical NOP source assembled unexpectedly')
    # A temporary data start is sufficient for RLN to calculate the text size
    # and publish actual symbol offsets. A second pass sets data immediately
    # after text and a third pass adjusts dehuff's internal absolute pointers.
    temp_base=0x825000
    first=link_cmd(sdk,temp_base,'build/release_overlay_link',manifest)
    listing=run(first,ROOT/'build/release_overlay_link_first.log')
    rombase=0x800000
    expected={'gpprog':0x813578,'_alloc_it':0x81AE08,
      '_free_bnd':0x81AF3C,'_use_bnd':0x81B032,
      '_alloc':0x81B0B8,'_morecore':0x81B158,
      '_free':0x81B1AE,'_sbrk':0x81B24A,
      '_init_alloc':0x81B29E}
    found={}
    for symbol,address in expected.items():
        m=re.search(r'\b'+re.escape(symbol)+r'\s+G\s+([A-F0-9]{8})',listing)
        if not m:raise RuntimeError('Retail-layout source symbol missing: '+symbol)
        found[symbol]=int(m.group(1),16)
        if found[symbol]!=address:raise RuntimeError(f'{symbol} at {found[symbol]:#x}, expected {address:#x}')
    absb=(ROOT/'build/release_overlay_link.abs').read_bytes()
    text_size,data_size,bss=struct.unpack_from('>III',absb,2)
    data_base=0x802000+text_size
    if data_base != 0x81D000:
        raise RuntimeError(f'Expected original historical data start 0x81D000; got {data_base:#x}')
    if data_base%8:raise RuntimeError('Unaligned code segment')
    # Remove prior relocated dehuff output so preliminary link uses original.
    relocated=ROOT/'build/relocated_resources/dehuff.bin'
    if relocated.exists():relocated.unlink()
    main_cmd=link_cmd(sdk,data_base,'build/release_overlay_link',manifest)
    listing=run(main_cmd,ROOT/'build/release_overlay_link_second.log')
    match=re.search(r'\bdehuff\s+G\s+([A-F0-9]{8})',listing)
    if not match:raise RuntimeError('Missing dehuff symbol in linker map')
    new_base=int(match.group(1),16)
    relocate(new_base)
    listing=run(link_cmd(sdk,data_base,'build/release_overlay_link',manifest),ROOT/'build/release_overlay_link_final.log')
    check=re.search(r'\bdehuff\s+G\s+([A-F0-9]{8})',listing)
    if not check or int(check.group(1),16)!=new_base:raise RuntimeError('dehuff relocated again in final link')
    absb=(ROOT/'build/release_overlay_link.abs').read_bytes()
    t,d,b=struct.unpack_from('>III',absb,2)
    if t!=text_size or b!=bss or t+d>0x1fe000:raise RuntimeError('Unexpected sections / ROM overflow')
    payload=bytearray(absb[36:36+t+d]);retail_start=START-0x2000
    if payload[retail_start:retail_start+4]!=b'\x00'*4:
        raise RuntimeError('DSP linker padding changed; NOP placement unsafe')
    payload[retail_start:retail_start+4]=padding
    if payload[retail_start:retail_start+C_START-START]!=ref[START:C_START]:
        raise RuntimeError('Integrated source GPU region disagrees with retail')
    late_begin,late_end=0x1C814,0x1D000
    late_is_exact=payload[late_begin-0x2000:late_end-0x2000]==ref[late_begin:late_end]
    if not late_is_exact and not a.allow_edited_retail_tail:
        raise RuntimeError('Recovered retail tail changed: set --allow-edited-retail-tail for deliberate same-size edits')
    # RLN leaves zeros at three historical inter-object padding sites.
    # Assemble their five NOP instructions from a separately commented
    # source module and replace *only* these verified unused slots.
    helper_nops_obj=ROOT/'assets/native/rom/source/linker_nops.o'
    run([sdk/'tools/bin/rmac','-fb','-u','-o',helper_nops_obj,
         ROOT/'assets/native/rom/source/LINKER_NOP_RELEASE.S'])
    helper_nops=helper_nops_obj.read_bytes()[32:42]
    if helper_nops!=bytes.fromhex('4e71'*5):
        raise RuntimeError('Helper NOP source did not assemble as five NOPs')
    for file_offset,count,pos in [(0x1B2CE,2,0),(0x1B544,4,2),(0x1C394,4,6)]:
        index=file_offset-0x2000
        if payload[index:index+count]!=b'\x00'*count:
            raise RuntimeError(f'Unsafe helper alignment replacement at {file_offset:#x}')
        payload[index:index+count]=helper_nops[pos:pos+count]
        if payload[index:index+count]!=ref[file_offset:file_offset+count]:
            raise RuntimeError('Reassembled helper padding differs from retail')
    target=Path(a.output)
    if not target.is_absolute():target=ROOT/target
    result=bytearray(ref[:0x2000]+payload+bytes(0x200000-0x2000-len(payload)))
    if result[0x400:0x408]!=bytes.fromhex('0404040400802000'):
        raise RuntimeError('Cartridge marker wrong')
    with tempfile.TemporaryDirectory(prefix='club_sign_') as tmp:
        p=Path(tmp)/'Club12.rom';p.write_bytes(result)
        run([sdk/'tools/bin/jagcrypt','-u',p.name],cwd=tmp,timeout=120)
        signed=(Path(tmp)/'Club12.U1').read_bytes()
    if signed[0x2000:]!=result[0x2000:] or len(signed)!=0x200000:
        raise RuntimeError('Cryptographic header regeneration altered payload')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(signed)
    matches=sum(x==y for x,y in zip(signed[0x2000:0x1d000],ref[0x2000:0x1d000]))
    summary=dict(status='INDEPENDENT CPU + INTEGRATED 1994 GPU containers; retail resources still required',
       sha256=hashlib.sha256(signed).hexdigest(),size=len(signed),text_bytes=t,
       data_bytes=d,bss_bytes=b,resource_bytes=d,
       verified_gpu_region=f'0x{START:X}-0x{C_START:X}',gpu_region_bytes=C_START-START,
       source_gpu_containers=12,retail_tail_source_is_exact=late_is_exact,art_source_rebuild=art_result,recovered_retail_cpu_tail_bytes=0x1D000-0x1C814,retail_helper_symbols={k:hex(v) for k,v in found.items()},
       cpu_match_through_1d000=dict(matches=matches,total=0x1d000-0x2000),
       needs_emulator_test=True,reference_retained_for_native_assets=True)
    (ROOT/'build/source_integrated.json').write_text(json.dumps(summary,indent=2)+'\n')
    print('LINKED bootstrap_link ROM',target,'SHA256',summary['sha256'])
    print('SOURCE-EXACT GPU region 0x13574-0x1AE08:',C_START-START,'bytes')
    print('CPU+GPU same-address match to 0x1D000:',matches,'/',0x1d000-0x2000)

if __name__=='__main__':main()
