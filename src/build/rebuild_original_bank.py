#!/usr/bin/env python3
"""CLUB DRIVE — reconstruct original retail-layout cartridge from source files.

RETROSPECTIVE SOURCE-RECOVERY NOTES (2026, not original Atari commentary)
-------------------------------------------------------------------------
1994 ALN links 68000 TEXT to $81D000, followed by DEHUFF, graphics,
GPU utility containers, compressed art, masks, audio, PLAYDATA and INFLATE
constant tables, world files and finally WAITPLAY.CRY.

No reference cartridge payload bytes are read by this packer. The caller must
supply a separately source-linked 68000 cartridge, assembled GPU binaries,
original source assets and the explicitly recovered WAITPLAY image + 16-byte
footer. Original-data addressing is reconstructed from the VERIFIED retail_link
relocation audit, not guessed / searched during packing.

A separate --reference option provides only post-build verification. An
unmodified source and resources must make an exact 2MiB retail ROM. For a
modified resource, --allow-resource-edit skips byte equality to retail but
still enforces fixed slot boundaries and re-authenticates the full cartridge.
No claim is made that proprietary .JAG/.Z encoded resources are recompilable
from arbitrary source pictures: where such converters are unavailable, the
original recovered compressed files are transparently used as sources.
"""
from asset_paths import asset_file
import argparse,hashlib,json,struct,subprocess,tempfile,zipfile
from pathlib import Path
from PIL import Image
from compile_recovered_resources import records as compression_records, rebuild as rebuild_gzip

ROOT=Path(__file__).resolve().parent.parent
START,DATA_END=0x1D000,0x200000
OBJ_HEADER=32
GPU_NAMES=('adjblack','uncomp','lighten','cross','fade')

def load_rom(p):
    p=Path(p)
    if p.suffix.lower()=='.zip':
        with zipfile.ZipFile(p) as z:
            names=[n for n in z.namelist() if n.lower().endswith('.j64')]
            if len(names)!=1:raise ValueError('Expected exactly one .j64 in ROM archive')
            return z.read(names[0])
    return p.read_bytes()

def object_sections(name):
    b=(ROOT/'build/obj'/f'{name}.o').read_bytes()
    if b[:4]!=bytes.fromhex('00000107'):
        raise ValueError(f'{name}.o is not an Atari 68000 relocation object')
    t,d,bss=struct.unpack_from('>III',b,4)
    if t+d+OBJ_HEADER>len(b):raise ValueError(f'{name}.o truncated')
    return b[OBJ_HEADER:OBJ_HEADER+t],b[OBJ_HEADER+t:OBJ_HEADER+t+d]

class Bank:
    def __init__(self):
        self.data=bytearray(DATA_END-START)
        self.cover=bytearray(len(self.data))
        self.records=[]
        self.compressed=[]
    def put(self,start,data,label,kind='recovered source',same_size=None):
        data=bytes(data)
        if same_size is not None and len(data)!=same_size:
            raise ValueError(f'{label}: length {len(data)} differs from original slot {same_size}')
        i=start-START
        if i<0 or i+len(data)>len(self.data):raise ValueError(f'{label}: out of data bank')
        # A few old resource manifests contain supersets of another named file.
        # Permit overlaps ONLY when both independently named sources agree.
        for j,v in enumerate(data):
            if self.cover[i+j] and self.data[i+j]!=v:
                raise ValueError(f'{label}: conflicting overlap at {start+j:#x}')
        self.data[i:i+len(data)]=data
        self.cover[i:i+len(data)]=b'\x01'*len(data)
        self.records.append(dict(symbol=label,offset=f'{start:#08x}',length=len(data),
                                 kind=kind,sha256=hashlib.sha256(data).hexdigest()))
    def finish(self):
        holes=[];st=None
        for i,ok in enumerate(self.cover):
            if not ok and st is None:st=i
            if ok and st is not None:holes.append((st+START,i+START));st=None
        if st is not None:holes.append((st+START,DATA_END))
        if any(a==b for a,b in holes):raise AssertionError('Empty hole')
        if any(b-a>7 for a,b in holes):raise ValueError(f'Non-alignment gap(s): {holes}')
        # All surviving unfilled holes are <=7 byte ALN phrase-alignment gaps.
        # They are explicitly zero-filled; the normal retail comparison checks
        # this historical assumption rather than silently copying ROM gaps.
        for a,b in holes:self.records.append(dict(symbol='ALIGN_ZERO',offset=f'{a:#08x}',length=b-a,kind='linker zero padding'))
        return len(holes),sum(b-a for a,b in holes)

def source_bank(a):
    bank=Bank(); layout=json.loads((ROOT/'build/retail_link_data_layout.json').read_text())
    rows=layout['entries']
    # Recovered raw resource files are now actual build inputs, not merely
    # forensic references. Build only fixed-size gzip members here; passing a
    # larger compressed stream would displace adjacent retail data pointers.
    gzip_by_offset={r['rom_start']:r for r in compression_records()}
    seen=set()
    for x in rows:
        source=(asset_file(x['recovered_asset'])).read_bytes()
        if x['retail_offset'] in gzip_by_offset:
            rec=gzip_by_offset[x['retail_offset']]
            source,detail=rebuild_gzip(rec,source,allow_edits=a.allow_edited_resources)
            bank.compressed.append(detail)
            seen.add(rec['rom_start'])
        bank.put(x['retail_offset'],source,x['symbol'],
                 'recompiled recovered gzip resource' if x['retail_offset'] in gzip_by_offset else 'recovered named resource',x['size'])
    if seen!=set(gzip_by_offset):
        raise ValueError('A recovered gzip resource was not present in the layout map')
    # GPU program header: 32-bit Tom load address, then 32-bit program length.
    # The modern source-assembled file includes both header words (8 bytes).
    p=0x537e0
    for n in GPU_NAMES:
        binary=(ROOT/'build/gpu_link'/f'{n}.bin').read_bytes()
        bank.put(p,binary,'GPU_'+n.upper(),'assembled GPU loader')
        p+=len(binary)
        padding=(-p)&7
        bank.put(p,bytes(padding),'GPU_'+n.upper()+'_ALIGN','linker zero padding')
        p+=padding
    if p!=0x54118:raise ValueError('GPU utility block no longer matches original 0x54118 boundary')
    # ALN's audio bank ends with a seven-byte alignment gap. The following
    # graphics/data objects were ALWAYS linked after the audio resources.
    bank.put(0xe5689,bytes(7),'PLAYDATA_ALIGN','linker zero padding')
    _,graphics=object_sections('playdata')
    bank.put(0xe5690,graphics,'playdata.s','source-assembled 68000 DATA',19424)
    _,tables=object_sections('inflate')
    bank.put(0xea270,tables,'INFLATE.S_TABLES','source-assembled DEFLATE tables',282)
    bank.put(0xea38a,bytes(6),'INFLATE_ALIGN','linker zero padding')
    # The final Makefile's WAITPLAY.CRY occupies 320x50 CRY16 pixels.
    # The byte-source PNG stores the exact two CRY bytes in R/G channels;
    # preview PNGs are visual approximations and must never be compiled.
    image=Image.open(ROOT/'assets/native/resources/data/WAITPLAY_cry16_source.png').convert('RGB')
    if image.size!=(320,50):raise ValueError('WAITPLAY pixel source must be 320x50')
    pixels=image.tobytes();wait=bytearray()
    for i in range(0,len(pixels),3):wait.extend(pixels[i:i+2])
    bank.put(0x1f82f0,wait,'WAITPLAY.CRY','editable CRY16 PNG',32000)
    bank.put(0x1ffff0,(ROOT/'assets/native/resources/data/cartridge_trailer_16.bin').read_bytes(),
             'CART_TRAILER','explicitly recovered opaque cartridge metadata',16)
    return bank

def reconstruct(source,audit,bank,allow_edit):
    if len(source)!=DATA_END:raise ValueError('Source ROM must be exactly 2MiB')
    instr=bytearray(source[0x2000:START]);j=json.loads(audit.read_text())
    if not allow_edit and hashlib.sha256(source).hexdigest()!=j['source_sha256']:
        raise ValueError('Relocation audit was generated for another source ROM')
    mappings=j['long_form_relocations']+j['low_word_only_relocations']+j['internal_structure_relocations']
    if len(mappings)!=141:raise ValueError('Unexpected CPU relocation count')
    for rec in mappings:
        off=int(rec['file_offset'],16);p=off-0x2000
        src=int(rec['source_target'],16);dest=int(rec['retail_target'],16)
        if p<0 or p+4>len(instr):raise ValueError('Relocation outside executable')
        if int.from_bytes(instr[p:p+4],'big')!=src:raise ValueError(f'Source relocation changed at {off:#x}')
        instr[p:p+4]=dest.to_bytes(4,'big')
    # Never use retail bytes to fill the reconstructed cartridge. The header
    # comes from our own already-built cartridge (which itself has a retail-
    # derived authentication template). Auth is re-generated below.
    cart=bytearray(DATA_END)
    cart[:0x2000]=source[:0x2000]
    cart[0x2000:START]=instr
    cart[START:DATA_END]=bank.data
    return cart,len(mappings)

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source',required=True,type=Path,help='Source-linked Club Drive retail_link/retail_data cartridge')
    ap.add_argument('--audit',type=Path,default=ROOT/'build/retail_link_relocation_audit.json')
    ap.add_argument('--sdk',required=True,type=Path)
    ap.add_argument('--output',type=Path,default=ROOT/'Club_Drive.j64')
    ap.add_argument('--reference',type=Path,help='Optional retail comparison, never used as ROM payload source')
    ap.add_argument('--allow-edited-resources',action='store_true',help='Allow non-retail assets of identical slot sizes and source ROM differences')
    ap.add_argument('--skip-auth',action='store_true',help='Debug only; output is not authenticated after modifications')
    ap.add_argument('--manifest',type=Path,default=ROOT/'build/retail_data_retail_bank_index.json')
    a=ap.parse_args()
    bank=source_bank(a)
    nholes,zeros=bank.finish()
    raw=load_rom(a.source)
    assembled,nreloc=reconstruct(raw,a.audit,bank,a.allow_edited_resources)
    bank_matches=None
    if a.reference:
        target=load_rom(a.reference)
        if len(target)!=DATA_END:raise ValueError('Reference ROM is not 2MiB')
        bank_matches=assembled[START:]==target[START:]
        if not a.allow_edited_resources and not bank_matches:
            bad=next(i for i in range(START,DATA_END) if assembled[i]!=target[i])
            raise ValueError(f'Reconstructed data bank differs from retail at {bad:#x}')
        if not a.allow_edited_resources and assembled[0x2000:]!=target[0x2000:]:
            bad=next(i for i in range(0x2000,DATA_END) if assembled[i]!=target[i])
            raise ValueError(f'Reconstructed cartridge payload differs at {bad:#x}')
    if a.skip_auth:
        result=bytes(assembled)
    else:
        with tempfile.TemporaryDirectory(prefix='club16_auth_') as td:
            dest=Path(td);(dest/'SOURCE.ROM').write_bytes(assembled)
            p=subprocess.run([str(a.sdk.resolve()/'tools/bin/jagcrypt'),'-u','SOURCE.ROM'],cwd=dest,
                text=True,capture_output=True,timeout=120)
            if p.returncode:raise RuntimeError(f'jagcrypt failed: {p.stdout} {p.stderr}')
            result=(dest/'SOURCE.U1').read_bytes()
        if len(result)!=DATA_END or result[0x2000:]!=assembled[0x2000:]:
            raise ValueError('Jagcrypt unexpectedly altered the cartridge payload')
    result_path=a.output if a.output.is_absolute() else ROOT/a.output
    result_path.parent.mkdir(parents=True,exist_ok=True)
    result_path.write_bytes(result)
    report=dict(description='2026 reconstructed source/data/verified relocations, with opaque JPEG/JAG source bytes where original converter is missing',
        bank_bytes=DATA_END-START,exact_asset_count=len([x for x in bank.records if x['kind']!='linker zero padding']),
        linker_padding_gaps=nholes,linker_padding_zero_bytes=zeros,relocations=nreloc,
        data_bank_matches_reference=bank_matches,edited_asset_mode=a.allow_edited_resources,
        sha256=hashlib.sha256(result).hexdigest(),cartridge_matches_reference=(result==load_rom(a.reference) if a.reference else None),
        reference_payload_used_in_output=False,authentication_header_is_retail_derived=True,
        source_records=bank.records,compressed_resources=bank.compressed)
    manifest=a.manifest if a.manifest.is_absolute() else ROOT/a.manifest
    manifest.parent.mkdir(parents=True,exist_ok=True);manifest.write_text(json.dumps(report,indent=2)+'\n')
    print('RETAIL_DATA: reconstructed original data layout from recovered resource files + source-assembled object data')
    print('Resources:',report['exact_asset_count'],'relocations',nreloc,'zero padding',zeros,'bytes in',nholes,'gaps')
    print('Gzip resources:',len(bank.compressed),'recompiled:',sum(x['changed'] for x in bank.compressed))
    print('Bank identical to retail:',bank_matches,'full retail identity:',report['cartridge_matches_reference'])
    print('Output:',result_path,'SHA256',report['sha256'])

if __name__=='__main__':main()
