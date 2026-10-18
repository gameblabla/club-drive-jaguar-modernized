#!/usr/bin/env python3
"""Address-shift-aware 68000 binary audit against Club Drive retail.

Only uniquely matching 24-byte windows are counted. These windows establish
matching bytes, not the correctness or full identity of surrounding functions.
"""
from pathlib import Path
from collections import defaultdict,Counter
import argparse,hashlib,json,struct
from link_recovered_stage import load_rom,ROOT

def run():
 p=argparse.ArgumentParser();p.add_argument('--reference',type=Path,required=True)
 p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,default=ROOT/'build/cpu_anchor_report.json')
 args=p.parse_args();ref=load_rom(args.reference);rom=load_rom(args.source)
 if len(ref)!=len(rom)!=0x200000:raise ValueError('Expected 2 MiB cartridges')
 if len(ref)!=0x200000 or len(rom)!=0x200000:raise ValueError('Expected 2 MiB cartridges')
 exe=(ROOT/'build/source_link_trial.abs').read_bytes()
 if exe[:2]!=b'\x60\x1b':raise ValueError('Missing Atari ABS image')
 text_size=struct.unpack_from('>I',exe,2)[0]
 if not 0<text_size<0x20000:raise ValueError('Implausible executable size')
 # Retail code is intermixed with data; 0x1D000 is a conservative upper
 # scan bound, not an asserted final executable symbol.
 lo=0x2000;hi_ref=0x1d000;hi_src=lo+text_size;window=24;stride=2
 index=defaultdict(list)
 for i in range(lo,hi_ref-window+1,stride):
  b=ref[i:i+window]
  if len(set(b))>=6:index[b].append(i)
 anchors=[]
 for i in range(lo,hi_src-window+1,stride):
  b=rom[i:i+window];candidates=index.get(b,())
  if len(candidates)==1:anchors.append((i,candidates[0],candidates[0]-i))
 spans=[]
 if anchors:
  start=prev=anchors[0]
  for x in anchors[1:]:
   if x[2]==prev[2] and x[0]-prev[0]<=100 and x[1]-prev[1]<=100:prev=x
   else:
    spans.append((start,prev));start=prev=x
  spans.append((start,prev))
 longest=sorted(spans,key=lambda t:t[1][0]-t[0][0],reverse=True)[:30]
 first_different=next((i for i in range(lo,hi_src) if ref[i]!=rom[i]),None)
 hist=Counter(x[2] for x in anchors)
 result={'reference_sha256':hashlib.sha256(ref).hexdigest(),
   'source_sha256':hashlib.sha256(rom).hexdigest(),
   'whole_cartridge_diff_bytes':sum(a!=b for a,b in zip(ref,rom)),
   'cartridge_auth_header_diff_bytes':sum(a!=b for a,b in zip(ref[:lo],rom[:lo])),
   'cpu_source_text_size':text_size,'source_text_end_offset':hex(hi_src),
   'retail_cpu_candidate_scan_end':hex(hi_ref),'first_same_offset_mismatch':hex(first_different) if first_different else None,
   'unique_24byte_matches':len(anchors),'anchor_stride_bytes':stride,
   'major_address_shifts':[{'retail_minus_source':drift,'windows':count} for drift,count in hist.most_common(15)],
   'longest_unchanged_spans':[{'source_start':hex(a[0]),'source_last_anchor':hex(b[0]),
     'retail_start':hex(a[1]),'retail_last_anchor':hex(b[1]),
     'retail_minus_source':a[2],'matched_span_bytes':b[0]-a[0]+window} for a,b in longest],
   'limitations':'Exact 24-byte windows can be shifted, and do not prove entire routines match; all bytes at the same ROM offset are NOT identical.'}
 args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(result,indent=2)+'\n')
 print(f'CPU text {text_size} bytes; {len(anchors)} unique matching 24-byte windows despite address shifts')
 print(f'Cartridge byte differences: {result["whole_cartridge_diff_bytes"]} (boot header: {result["cartridge_auth_header_diff_bytes"]})')
 print('First same-address executable mismatch:',result['first_same_offset_mismatch'])
 for x in result['major_address_shifts'][:7]:print('offset delta',x['retail_minus_source'],'count',x['windows'])
if __name__=='__main__':run()
