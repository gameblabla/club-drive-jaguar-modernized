#!/usr/bin/env python3
"""Compile the original ART.S and create a linker-ready compressed art resource.

If the source assembles to the original decompressed resource, preserve the
historical .gz stream so the clean cartridge remains byte-identical locally.
If the artwork changes, generate an editable-resource gzip stream and let the
linker relocate all references, with jagcrypt authenticating the result.
No original graphics instruction or compressed bitstream is fabricated.
"""
import gzip, hashlib, json, struct, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
ORIGINAL=ROOT/'build/packed_sources/054118.gz'
DESTINATION=ROOT/'build/source_generated/art.gz'
MANIFEST=ROOT/'build/source_generated/art_index.json'

def prepare(sdk):
    obj=ROOT/'build/obj/art.o'
    data=obj.read_bytes()
    if len(data)<32 or data[:4]!=bytes.fromhex('00000107'):
        raise RuntimeError('Unexpected RMAC ART.S object format')
    length=struct.unpack_from('>I',data,4)[0]
    raw=data[32:32+length]
    if len(raw)!=length:raise RuntimeError('Incomplete assembled ART.S data')
    pristine=ORIGINAL.read_bytes()
    original=gzip.decompress(pristine)
    if len(raw)!=len(original):
        raise RuntimeError('ART.S must preserve its original decompressed data size for a safe overlay')
    pristine_match=(raw==original)
    DESTINATION.parent.mkdir(parents=True,exist_ok=True)
    if pristine_match:
        DESTINATION.write_bytes(pristine)
    else:
        DESTINATION.write_bytes(gzip.compress(raw,compresslevel=6,mtime=0))
    if gzip.decompress(DESTINATION.read_bytes())!=raw:
        raise RuntimeError('ART.S gzip round trip failed')
    result=dict(generated_from='ART.S',decompressed_bytes=length,
        compression='original gzip if source identical, newly generated gzip otherwise',
        exact_original_source=pristine_match,
        source_sha256=hashlib.sha256(raw).hexdigest(),
        packed_sha256=hashlib.sha256(DESTINATION.read_bytes()).hexdigest(),
        output=str(DESTINATION.relative_to(ROOT)))
    MANIFEST.write_text(json.dumps(result,indent=2)+'\n')
    return result
if __name__=='__main__':
    print(json.dumps(prepare(None),indent=2))
