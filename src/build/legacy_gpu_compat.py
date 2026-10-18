#!/usr/bin/env python3
"""GASM-to-RMAC compatibility preprocessor for the 1994 Jaguar source.

Only used for GPU programs which fail original rmac assembly. Expands includes
with lexical register aliases; original files are left intact for inspection.
Unresolved instructions/macros remain assembler errors, never silently stubs.
"""
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'build/compat_gpu'
ONCE={'jaguar.inc','blit.inc','joypad.inc','68kequ.inc','3d.inc','3dds.inc','tree.inc','time.gas'}
INC=re.compile(r'^\s*\.?include\s+["\']([^"\']+)["\']\s*',re.I)
REG=re.compile(r'^\s*(\w+)\s+REGEQU\s+([A-Za-z_]\w*)',re.I)
UNREG=re.compile(r'^\s*REGUNDEF\s+(\w+)',re.I)

class Port:
 def __init__(self):
  self.once=set();self.imports=[];self.report=[];self.equ=set();self.conditional_depth=0
 def resolve(self, key):
  name=key.replace('\\','/').split('/')[-1]
  p=ROOT/name
  if p.exists():return p
  p=ROOT/name.upper()
  if p.exists():return p
  p=ROOT/'compat_include'/name.lower()
  if p.exists():return p
  raise FileNotFoundError(key)
 def conv(self, p, regs=None, stack=()):
  if regs is None:regs={}
  if len(stack)>20:raise ValueError('recursive inclusion: '+repr(stack))
  output=[]
  for num,line in enumerate(p.read_text('latin1').splitlines(),1):
   origin=f'{p.name}:{num}'
   match=INC.match(line)
   if match and not line.lstrip().startswith(';'):
    try:q=self.resolve(match.group(1))
    except FileNotFoundError:
     self.report.append(f'MISSING INCLUDE {origin} {match.group(1)}'); output.append('; MISSING '+origin+' '+line);continue
    key=q.name.lower()
    if key in ONCE and key in self.once:
     output.append('; elided repeat include '+str(q))
     continue
    if key in ONCE:self.once.add(key)
    output.append('; BEGIN '+q.name)
    output += self.conv(q,regs,stack+(str(p),))
    output.append('; END '+q.name)
    continue
   body,sep,comment=line.partition(';')
   m=UNREG.match(body)
   if m:
    regs.pop(m.group(1),None)
    output.append('; GASM REGUNDEF '+m.group(1)+' ; '+origin)
    continue
   m=REG.match(body)
   if m:
    alias,target=m.groups()
    resolved=regs.get(target,regs.get(target.lower(),target))
    if re.fullmatch(r'[rR](?:[0-9]|[12][0-9]|3[01])',resolved):
     regs[alias]=resolved.lower()
     output.append(f'; legacy REGEQU {alias} => {resolved} ; {origin}')
     continue
    self.report.append('Unresolved REGEQU '+origin+':'+line)
   if re.match(r'^\s*\.(?:if|ifdef|ifndef)\b',body,re.I):self.conditional_depth+=1
   if re.match(r'^\s*\.endif\b',body,re.I):self.conditional_depth=max(0,self.conditional_depth-1)
   equ=re.match(r'^\s*([A-Za-z_][\w]*)\s+EQU\b',body,re.I)
   if equ:
    name=equ.group(1)
    if self.conditional_depth==0 and name in self.equ:
     output.append('; identical repeated EQU elided: '+origin+' '+line)
     continue
    
    if self.conditional_depth==0:self.equ.add(name)
   # Replace aliases only in code, never in comments. Preserve symbol directives.
   if body.strip() and not re.match(r'^\s*(?:equ|set|macro|endm)\b',body,re.I):
    for alias,reg in sorted(regs.items(),key=lambda x:-len(x[0])):
     body=re.sub(r'(?<![\w.#])'+re.escape(alias)+r'(?![\w.])',reg,body,flags=0)
   # DOS paths are supported through expanded includes, no stray backslashes.
   # GASM @1 denotes a macro argument; RMAC uses \1. Without this
   # substitution RMAC incorrectly assembles the literal number 1.
   body=re.sub(r'(?<!@)@([1-9])',lambda m:chr(92)+m.group(1),body)
   output.append(body+sep+comment)
  return output
 def run(self,base):
  self.once.clear();self.report.clear();self.equ.clear()
  lines=self.conv(ROOT/(base.lower()+'.gas'))
  dest=OUT/(base.lower()+'.gas')
  dest.write_text('\n'.join(lines)+'\n',encoding='latin1')
  return dest

if __name__=='__main__':
 import sys
 OUT.mkdir(exist_ok=True,parents=True)
 for src in sys.argv[1:]:
  p=Port();out=p.run(src);print(src,len(out.read_bytes()),'warnings',len(p.report));print('\n'.join(p.report[:10]))
