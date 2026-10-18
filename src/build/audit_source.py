#!/usr/bin/env python3
"""Independent ROM same-address audit for bootstrap_link, disaggregating CPU/GPU/resources."""
from pathlib import Path
import argparse,hashlib,json
from link_recovered_stage import load_rom, ROOT
REGIONS=[('startup_cpu',0x2000,0x13574),('historical_gpu_containers',0x13574,0x1AE08),('late_68000_helpers',0x1AE08,0x1D000),('early_resources',0x1D000,0x200000)]

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--reference',type=Path,required=True)
 p.add_argument('--source',type=Path,required=True)
 p.add_argument('--output',type=Path,default=ROOT/'build/source_byte_audit.json')
 a=p.parse_args();r=load_rom(a.reference);s=load_rom(a.source)
 assert len(r)==len(s)==0x200000
 rows=[]
 for name,lo,hi in REGIONS:
  eq=sum(x==y for x,y in zip(r[lo:hi],s[lo:hi]));rows.append(dict(name=name,start=f'{lo:#08x}',end=f'{hi:#08x}',same_address_bytes=eq,bytes=hi-lo,percent=round(100*eq/(hi-lo),4)))
 exact_gpu=(r[0x13574:0x1AE08]==s[0x13574:0x1AE08]);late_tail=(r[0x1C814:0x1D000]==s[0x1C814:0x1D000])
 output={'source_sha256':hashlib.sha256(s).hexdigest(),'retail_sha256':hashlib.sha256(r).hexdigest(),
 'region_comparisons':rows,'exact_integrated_gpu':exact_gpu,'exact_recovered_late_cpu_tail':late_tail,
 'code_same_address_bytes':sum(x==y for x,y in zip(r[0x2000:0x1D000],s[0x2000:0x1D000])),
 'code_comparison_length':0x1D000-0x2000,
 'whole_cartridge_byte_identical':r==s,
 'note':'Retail opcode tail bytes are source-assembled machine-word transcriptions, not reconstructed symbolic C compiler output.'}
 a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(output,indent=2)+'\n')
 print('CPU/GPU before $1D000:',output['code_same_address_bytes'],'/',output['code_comparison_length'])
 print('Exact GPU:',exact_gpu,'exact release-tail transcription:',late_tail)
 print('Whole-ROM match:',r==s)
if __name__=='__main__':main()
