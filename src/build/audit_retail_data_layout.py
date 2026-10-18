#!/usr/bin/env python3
"""Release-layout survey for CLUB Drive's source-linked ROM (retail_link).

The original 1994 Makefile interleaves prelinked JPEG/graphics resources,
audio, GPU loaders and the late C helpers. The modern RLN linker instead
places many data sections sequentially. This is a read-only, label-grounded
survey of the difference, NOT a relocator or a claimed full-ROM match.

Reference labels/lengths come from individually recovered source manifests,
not from guessing matching byte prefixes. Source addresses come from RLN's
actual published symbol map after the independent code has linked.
"""
import argparse,hashlib,json,re,collections,csv,struct
from pathlib import Path
from link_recovered_stage import ROOT,load_rom

def runtime_symbols(log: str):
    result = collections.defaultdict(set)
    for name,addr in re.findall(r'\b([A-Za-z_][\w.$]*)\s+G\s+([0-9A-F]{8})\b', log):
        result[name].add(int(addr,16))
    return result

def manifest_entries():
    records=[]
    spec=[('audio','assets/native/audio/bank/audio_index.json','assets','rom_start','size','file','assets/native/audio/bank'),
          ('graphics','assets/native/graphics/encoded/graphics_index.json','resources','start','slot_length','original_filename','assets/native/graphics/encoded'),
          ('helpers','assets/native/tools/helpers_index.json','resources','start','length','original_filename','assets/native/tools'),
          ('final','assets/native/graphics/final/final_assets_index.json','resources','start','length','original_filename','assets/native/graphics/final')]
    for kind,manifest,key,offset_field,size_field,file_field,directory in spec:
        for row in json.loads((ROOT/manifest).read_text())[key]:
            name=row['symbol'];off=row[offset_field];length=row.get(size_field)
            if length is None:
                length=row['slot_end']-off
            path=ROOT/directory/row[file_field]
            records.append(dict(kind=kind,symbol=name,retail_offset=off,size=length,
                                recovered_asset=str(path.relative_to(ROOT))))
    # Only compressed world files for which the original Makefile assigned a
    # symbol. All 22 gzip members remain in RECOVERED_RESOURCES for study.
    for row in json.loads((ROOT/'build/source_link_stage5.json').read_text())['resource_symbols']:
        if 'rom_start' not in row or row['verified_source'].startswith('GPU'):continue
        label=row['symbol'];original=int(row['rom_start'],16)
        path=ROOT/row['file']
        # Exclude double-labeled entries; the named graphics/final manifests
        # often give more authoritative original boundaries.
        if any(x['symbol']==label for x in records):continue
        records.append(dict(kind='compressed/world',symbol=label,retail_offset=original,
                            size=path.stat().st_size,recovered_asset=row['file']))
    return records

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--source',type=Path,required=True)
    parser.add_argument('--map',type=Path,default=ROOT/'build/release_overlay_link_final.log')
    parser.add_argument('--output',type=Path,default=ROOT/'build/retail_link_data_layout.json')
    a=parser.parse_args()
    retail,rebuilt=load_rom(a.reference),load_rom(a.source)
    if len(retail)!=len(rebuilt) or len(retail)!=0x200000:
        raise ValueError('This analysis requires two 2 MiB cartridges')
    symbols=runtime_symbols(a.map.read_text(errors='replace'))
    entries=[]
    for rec in manifest_entries():
        n=rec['symbol'];p=ROOT/rec['recovered_asset'];pos=rec['retail_offset'];length=rec['size']
        if not p.is_file():raise FileNotFoundError(p)
        recovered=p.read_bytes()
        if len(recovered)!=length:
            raise ValueError(f'{n}: recovered file length {len(recovered)} vs manifest {length}')
        if retail[pos:pos+length]!=recovered:
            raise ValueError(f'{n}: recovered asset no longer matches the release-ROM slot')
        addresses=sorted(symbols.get(n,[]))
        good=[]
        for addr in addresses:
            src_pos=addr-0x800000
            if 0<=src_pos<=len(rebuilt)-length:
                match=sum(x==y for x,y in zip(recovered,rebuilt[src_pos:src_pos+length]))
                good.append(dict(runtime_address=hex(addr),source_offset=hex(src_pos),
                  identical_bytes=match,source_matches_original=match==length,
                  displacement=src_pos-pos))
        if n=='dehuff':
            from audit_data_relocations_retail import normalized_dehuff_equal
            for record in good:
                where=int(record['source_offset'],16)
                match,count=normalized_dehuff_equal(recovered,rebuilt[where:where+length],
                                                  0x800000+pos,0x800000+where)
                record['source_matches_after_internal_address_fixups']=match
                record['verified_internal_pointer_relocations']=count if match else 0
        entries.append(dict(**rec,original_sha256=hashlib.sha256(recovered).hexdigest(),
                            source_addresses=good,source_symbol_present=bool(addresses),
                            original_slot_matches_built_rom=(retail[pos:pos+length]==rebuilt[pos:pos+length])))
    summary={}
    for kind in sorted({x['kind'] for x in entries}):
        subset=[x for x in entries if x['kind']==kind]
        summary[kind]=dict(assets=len(subset),recovered_exact=sum(x['size'] for x in subset),
            published_source_symbols=sum(x['source_symbol_present'] for x in subset),
            source_asset_exact_at_symbol=sum(any(y['source_matches_original'] for y in x['source_addresses']) for x in subset),
            source_asset_exact_after_verified_relocation=sum(any(y['source_matches_original'] or y.get('source_matches_after_internal_address_fixups',False) for y in x['source_addresses']) for x in subset),
            assets_in_original_slots=sum(x['original_slot_matches_built_rom'] for x in subset))
    source_hash=hashlib.sha256(rebuilt).hexdigest()
    data=dict(purpose='READ-ONLY evidence for fixed-address resource ordering',
      retail_sha256=hashlib.sha256(retail).hexdigest(),source_sha256=source_hash,
      retail_data_starts_at_rom_offset='0x1D000',source_data_starts_at_rom_offset='0x1D000',
      source_positions_are_taken_from_actual_linker_symbol_map=True,
      summary=summary,entries=sorted(entries,key=lambda x:(x['retail_offset'],x['symbol'])),
      caveat='Recovered files verified against ROM; source asset addresses can overlap because of reconstructed linker structure. This is not a fixed-address linker or evidence of full data identity.')
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(data,indent=2)+'\n')
    csvfile=a.output.with_suffix('.csv')
    with csvfile.open('w',newline='') as f:
        w=csv.writer(f)
        w.writerow(['kind','symbol','retail_offset','bytes','linked_offset','shift','same_asset_bytes_at_linked_offset','exact_asset_at_linked_offset','original_slot_matches_built'])
        for x in data['entries']:
            v=x['source_addresses'][0] if x['source_addresses'] else None
            w.writerow([x['kind'],x['symbol'],hex(x['retail_offset']),x['size'],
              v['source_offset'] if v else '',v['displacement'] if v else '',
              v['identical_bytes'] if v else '',v['source_matches_original'] if v else '',
              x['original_slot_matches_built_rom']])
    print('Retail data-slot survey:',sum(len(v) for v in [data['entries']]),'source-grounded resources')
    for key,value in summary.items():print(key,value)
    print('Wrote',a.output,'and',csvfile)
if __name__=='__main__':main()
