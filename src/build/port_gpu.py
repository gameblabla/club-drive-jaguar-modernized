from pathlib import Path
import re
files=[p for p in Path('.').iterdir() if p.is_file() and p.suffix.upper() in {'.GAS','.INC'} and p.name.upper() not in {'BNDHEAD.INC','3DDS.INC','VIDEO.INC','CONTROLR.INC','CAR.INC','68KEQU.INC','3D.INC'} and p.name==p.name.lower()]
for p in files:
 s=p.read_text('latin-1')
 s=re.sub(r'\bREGSET\b','REGEQU',s,flags=re.I)
 s=re.sub(r'^(\s*)XDEF\b',r'\1.globl',s,flags=re.I|re.M)
 s=re.sub(r'^(\s*)XREF\b',r'\1.extern',s,flags=re.I|re.M)
 s=re.sub(r'^(\s*)ALIGN\s+PHRASE\b',r'\1.phrase',s,flags=re.I|re.M)
 s=re.sub(r'^(\s*)ALIGN\s+LONG\b',r'\1.align 4',s,flags=re.I|re.M)
 # Legacy GASM numeric local labels are not supported by RMAC.
 lines=s.splitlines(keepends=True)
 defs={}
 for idx,line in enumerate(lines):
  m=re.match(r'^\s*(\d+)\$:',line)
  if m:defs.setdefault(m.group(1),[]).append(idx)
 for idx,line in enumerate(lines):
  if ';' in line:code,comment=line.split(';',1);comment=';'+comment
  else:code,comment=line,''
  def conv(m):
   num=m.group(1);candidates=defs.get(num,[])
   if not candidates:return m.group()
   near=min(candidates,key=lambda k:(abs(idx-k),k>idx))
   return f'_CDLOCAL_{num}_{near}'
  code=re.sub(r'(?<![\w.])(\d+)\$(?=:|\b|,|\s|$)',conv,code)
  # Missing # on literal RISC immediates in historical macros.
  code=re.sub(r'\b(shrq|shlq|addq|subq|addqt|subqt|rorq|rolq|cmpq|bset|bclr|btst)\s+(\d+)\s*,',r'\1 #\2,',code,flags=re.I)
  lines[idx]=code+comment
 s=''.join(lines)
 if s!=p.read_text('latin-1'):p.write_text(s,encoding='latin-1')
print('transformed',len(files),'GPU source/includes')
