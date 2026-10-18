#!/usr/bin/env python3
"""Expand GASM @1 and @@ macros to standard Jaguar instructions for RMAC.
Only handles the macro grammar used by gpunzip.gas, and fails loudly otherwise.
"""
import re
from pathlib import Path
BASE=Path(__file__).resolve().parent.parent
src=BASE/'gpunzip.gas'
lines=src.read_text('latin1').splitlines()
output=[];macros={};i=0;enabled=[True];num=0
while i<len(lines):
 line=lines[i];i+=1
 clean=line.split(';')[0].strip()
 if re.fullmatch(r'\.if\s+(?:0|1)',clean,re.I):
  enabled.append(enabled[-1] and bool(int(clean.split()[-1])));continue
 if clean.lower()=='.else':
  if len(enabled)<2:raise ValueError('.else without .if')
  ancestor=enabled[-2]; enabled[-1]=ancestor and not enabled[-1];continue
 if clean.lower()=='.endif':
  if len(enabled)<2:raise ValueError('.endif without .if')
  enabled.pop();continue
 if not enabled[-1]:continue
 ma=re.fullmatch(r'MACRO\s+(\w+)',clean,re.I)
 if ma:
  name=ma.group(1).upper();body=[]
  while i<len(lines):
   l=lines[i];i+=1
   if re.match(r'^\s*ENDM\b',l,re.I):break
   body.append(l)
  else:raise ValueError('macro without ENDM')
  macros[name]=body
  continue
 if re.match(r'^\s*\.globl\s+[a-zA-Z_][a-zA-Z_0-9]*$',clean,re.I):
  # GASM's exported REGEQU names cannot be exported by RMAC as link symbols.
  # gpunzip.gas is emitted as a raw executable blob; these exports aren't used.
  output.append('; removed GASM register export: '+line);continue
 ma=re.match(r'^\s*(\w+)\s+([\w#]+)\s*(?:;.*)?$',line)
 if ma and ma.group(1).upper() in macros:
  name,arg=ma.groups(); num+=1
  for b in macros[name.upper()]:
   # GASM @@ local labels in macro expansions are unique per invocation.
   x=re.sub(r'\b([A-Za-z_][\w]*)@@',lambda m:f'_GASM_{num}_{m.group(1)}',b)
   x=x.replace('@1',arg)
   output.append(x)
  continue
 if '@@' in clean or re.search(r'\b(?:NEEDBITS|DUMPBITS|FLUSH)\b',clean,re.I):
  raise ValueError(f'unsupported macro at line {i}: {line}')
 output.append(line)
if len(enabled)!=1:raise ValueError('unclosed conditional')
path=BASE/'build/compat_gpu/gpunzip.gas';path.parent.mkdir(parents=True,exist_ok=True)
path.write_text('\n'.join(output)+'\n',encoding='latin1')
print('GASM macros expanded:',num,'instructions output lines:',len(output))
