#!/usr/bin/env python3
"""Recover missing Atari linker aliases from the original synth OJ symbol table."""
from pathlib import Path
import json,struct
ROOT=Path(__file__).resolve().parent.parent
OJ=(ROOT/'assets/native/toolchain/FULSYN.OJ').read_bytes()

def named_addr(name):
 # Legacy Atari symbol records: 8-byte ASCII name, 16-bit flags, 32-bit
 # value. The address follows the name (not four bytes before it).
 text=int.from_bytes(OJ[2:6],'big');size=int.from_bytes(OJ[14:18],'big')
 off=28+text+int.from_bytes(OJ[6:10],'big')
 matches=[]
 for pos in range(off,off+size,14):
  name_here=OJ[pos:pos+8].split(b'\0')[0].decode('ascii')
  if name_here==name:
   flag=int.from_bytes(OJ[pos+8:pos+10],'big')
   matches.append((flag,struct.unpack_from('>I',OJ,pos+10)[0]))
 if len(matches)!=1:raise ValueError(f'{name}: expected one legacy symbol entry; got {matches}')
 if name not in ('SCORE_AD','TIMER_AD') and matches[0][0]!=0xa000:
  raise ValueError(f'{name}: not marked as a legacy absolute DSP symbol')
 return matches[0][1]

# Jaguar hardware JOYSTICK read/write register, SDK jaguar.inc JOYSTICK.
joy=0xF14000
score=named_addr('SCORE_AD')
timer=named_addr('TIMER_AD')
extras={name:named_addr(name) for name in ('DSPORG','VOLUME','PATCHLOC','FULSYN_E')}
if not (0xF1B000<=score<0xF1D000 and 0xF1B000<=timer<0xF1D000):raise ValueError('Unexpected Jerry local address range')
lines=['; Recovered hardware and synth compatibility aliases',
       '; F14000 is the JOYSTICK read/write register in Jaguar hardware map.',
       '; Audio addresses below come from the original FULSYN.OJ symbol table.',
       '\t.globl JOYIN,JOYOUT,SCORE_ADD,TIMER_ADD,DSPORG,VOLUME,PATCHLOC,FULSYN_E',
       f'JOYIN\tEQU\t${joy:06X}',f'JOYOUT\tEQU\t${joy:06X}',
       f'SCORE_ADD\tEQU\t${score:06X}',f'TIMER_ADD\tEQU\t${timer:06X}',
       *[f'{k}\tEQU\t${v:06X}' for k,v in extras.items()],
       '; The original showcoord flag is exported by tables.s; no duplicate BSS byte.', '']
(ROOT/'LEGACY_EQUATES_RECOVERED.S').write_text('\n'.join(lines))
(ROOT/'build/legacy_equates.json').write_text(json.dumps({'JOYIN':hex(joy),'JOYOUT':hex(joy),
   'SCORE_ADD':hex(score),'TIMER_ADD':hex(timer),'showcoord':'existing tables.s label; no BSS allocated',
   **{k:hex(v) for k,v in extras.items()}},indent=2)+'\n')
print('Recovered legacy Jaguar equates:',hex(joy),hex(score),hex(timer))
if __name__=='__main__':pass
