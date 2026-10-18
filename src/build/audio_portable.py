#!/usr/bin/env python3
"""audio_portable: metadata-free WAV/SMF MIDI authoring with external, SHA-guarded provenance.

The audio_native RIFF and MIDI metadata-bearing source formats remain available, untouched.
Portable MIDI is intentionally restrictive: each native voice must retain the
same note-on/off event sequence. Native jump, patches, and other event words
remain authoritative from the original SCR and are never inferred from MIDI.
"""
from __future__ import annotations
import argparse, hashlib, json, math, struct
from collections import defaultdict
from pathlib import Path
import os
import audio_roundtrip as a

BASE=Path(__file__).resolve().parent.parent
ROOT=BASE/'assets'/'sounds'
WAV=ROOT/'wav'
MIDI=BASE/'assets'/'music'/'midi'
OUT=ROOT/'compiled'
INDEX=ROOT/'audio_catalog.json'
PPQ=480

def _original(r):
    b=(a.ORIGINAL/r['file']).read_bytes()
    if a.sha(b)!=r['sha256'] or len(b)!=r['size']:
        raise ValueError('Archived native source mismatch: '+r['file'])
    return b

def plain_wav(native:bytes)->bytes:
    fmt=struct.pack('<HHIIHH',1,1,a.PREVIEW_HZ,a.PREVIEW_HZ*2,2,16)
    body=b'WAVE'+a.chunk(b'fmt ',fmt)+a.chunk(b'data',a.decode_f16(native))
    return b'RIFF'+struct.pack('<I',len(body))+body

def import_wav(blob:bytes,original:bytes)->bytes:
    groups=list(a.chunks(blob))
    fmts=[payload for kind,payload in groups if kind==b'fmt ']
    datas=[payload for kind,payload in groups if kind==b'data']
    if len(fmts)!=1 or len(datas)!=1:raise ValueError('Exactly one WAV fmt and data chunk required')
    fmt=fmts[0]
    if len(fmt)<16 or struct.unpack_from('<HH',fmt)!=(1,1) or struct.unpack_from('<HH',fmt,12)!=(2,16):
        raise ValueError('WAV must be PCM mono 16 bit')
    if struct.unpack_from('<I',fmt,4)[0]!=a.PREVIEW_HZ:
        raise ValueError('WAV sample rate changed; pitch/resampling needs an explicit workflow')
    pcm=datas[0]
    if len(pcm)!=2*len(original):raise ValueError('WAV sample count changed; retail bank uses fixed slots')
    return a.encode_f16(pcm,original)

def _voice_notes(events):
    active={};result=[]
    for index,(tick,word) in enumerate(events):
        typ=word>>29
        if typ not in (0,4):continue
        voice=(word>>26)&7
        if typ==4:
            if voice in active:raise ValueError('Overlapping FullSynth voice is unsupported')
            midi_note=a.mid_note((word>>7)&0x3fff)
            active[voice]=midi_note
            result.append((index,tick,voice,'on',midi_note,word&127))
        else:
            if voice not in active:raise ValueError('FullSynth note-off without active note')
            result.append((index,tick,voice,'off',active.pop(voice),0))
    return result

def plain_midi(native:bytes,name:str)->bytes:
    events=a.native_events(native)
    voices=defaultdict(list)
    for i,t,v,k,n,vel in _voice_notes(events):
        voices[v].append((t,bytes([0x90|v if k=='on' else 0x80|v,n,vel])))
    # Tracks are segregated by native voice for painless DAW editing.
    conductor=[(0,a.meta(3,name.encode('utf-8'))),(0,a.meta(0x51,b'\x07\xa1\x20'))]
    tracks=[a.trk(conductor)]
    for v in sorted(voices):
        tracks.append(a.trk([(0,a.meta(3,('FullSynth voice '+str(v)).encode('utf-8')))] + voices[v]))
    return b'MThd'+struct.pack('>IHHH',6,1,len(tracks),PPQ)+b''.join(tracks)

def parse_notes(midi:bytes):
    if len(midi)<14 or midi[:4]!=b'MThd':raise ValueError('Missing MIDI header')
    hlen=struct.unpack_from('>I',midi,4)[0]
    if hlen<6 or 8+hlen>len(midi):raise ValueError('Bad MIDI header length')
    form,ntracks,division=struct.unpack_from('>HHH',midi,8)
    if form not in (0,1) or not ntracks or division&0x8000 or division==0:
        raise ValueError('Expected type 0/1 MIDI with PPQ timebase')
    pos=8+hlen;voices=defaultdict(list)
    for tr in range(ntracks):
        if pos+8>len(midi) or midi[pos:pos+4]!=b'MTrk':raise ValueError('Missing MIDI track')
        size=struct.unpack_from('>I',midi,pos+4)[0];end=pos+8+size
        if end>len(midi):raise ValueError('Truncated MIDI track')
        data=midi[pos+8:end];pos=end;idx=0;tick=0;running=None
        while idx<len(data):
            delta,idx=a.read_vlq(data,idx);tick+=delta
            if idx>=len(data):raise ValueError('Truncated MIDI status')
            status=data[idx]
            if status<128:
                if running is None:raise ValueError('Missing MIDI running status')
                status=running
            else:
                idx+=1
                if 0x80<=status<=0xef:running=status
                else:running=None
            if status==0xff:
                if idx>=len(data):raise ValueError('Truncated MIDI meta')
                kind=data[idx];idx+=1;n,idx=a.read_vlq(data,idx)
                if idx+n>len(data):raise ValueError('Truncated MIDI meta data')
                idx+=n
            elif status in (0xf0,0xf7):
                n,idx=a.read_vlq(data,idx)
                if idx+n>len(data):raise ValueError('Truncated MIDI SysEx')
                idx+=n
            elif 0x80<=status<=0xef:
                kind=status&0xf0;voice=status&15;n=1 if kind in (0xc0,0xd0) else 2
                if idx+n>len(data):raise ValueError('Truncated MIDI channel message')
                payload=data[idx:idx+n];idx+=n
                if kind in (0x80,0x90):
                    note,vel=payload
                    if note>127 or vel>127:raise ValueError('Bad MIDI note data')
                    cls='on' if kind==0x90 and vel>0 else 'off'
                    native_tick=tick*PPQ
                    if native_tick%division:raise ValueError('PPQ conversion gives fractional native tick')
                    voices[voice].append((native_tick//division,cls,note,vel))
                else:
                    raise ValueError('MIDI controller/program/pitch-bend events cannot be mapped to Jaguar patches')
            else:raise ValueError(f'Unsupported MIDI status {status:#x}')
    if pos!=len(midi):raise ValueError('Extra bytes after MIDI tracks')
    # Type 1 editors may move voices between tracks; chronological order per
    # channel still carries the original FullSynth monophonic event identity.
    for notes in voices.values():notes.sort(key=lambda item:item[0])
    return voices

def import_midi(midi:bytes,original:bytes)->bytes:
    baseline=a.native_events(original)
    reference=_voice_notes(baseline)
    voices=parse_notes(midi)
    expected=defaultdict(list)
    for i,t,v,k,n,vel in reference:expected[v].append((i,t,k,n,vel))
    if set(voices)!=set(expected):raise ValueError('MIDI voice set differs from native SCR')
    replacements={}
    for voice,ref in expected.items():
        modified=voices[voice]
        if len(modified)!=len(ref):raise ValueError(f'Voice {voice}: event count changed')
        sounding=None
        for (i,t_orig,k,base_note,orig_vel),(tick,kind,note,vel) in zip(ref,modified):
            if kind!=k:raise ValueError(f'Voice {voice}: note-on/off order changed')
            if k=='on':
                if sounding is not None:raise ValueError('Overlapping notes in a native monophonic voice')
                sounding=note
            else:
                if sounding!=note:raise ValueError('Note-off pitch does not match its note-on')
                sounding=None
            replacements[i]=(tick,note,vel,base_note)
    words=[];last=-1
    for i,(t,w) in enumerate(baseline):
        typ=w>>29
        if typ in (0,4):
            t,note,vel,base_note=replacements[i]
            if typ==4:
                freq=(w>>7)&0x3fff
                if note!=base_note:
                    edited=round(freq*2**((note-base_note)/12))
                    if not 1<=edited<=0x3fff:raise ValueError('Native frequency overflow')
                    w=(w&~(0x3fff<<7))|(edited<<7)
                w=(w&~127)|vel
        if t<last:raise ValueError('MIDI edit reordered native event stream (including its loop event)')
        if t>0xffffffff:raise ValueError('Native tick overflow')
        words.append(struct.pack('>II',t,w));last=t
    return b''.join(words)+b'\x7f\xff\xff\xff'

def export():
    for directory in (WAV,MIDI,OUT):directory.mkdir(parents=True,exist_ok=True)
    assets=[]
    for r in a.records():
        native=_original(r)
        fname=Path(r['file']).stem
        if r['kind']=='f16':
            path=WAV/(fname+'.wav');plain=plain_wav(native)
        else:
            path=MIDI/(fname+'.mid');plain=plain_midi(native,fname)
        path.write_bytes(plain)
        assets.append({'file':r['file'],'kind':r['kind'],'original_sha256':r['sha256'],
                       'native_size':r['size'],'portable_file':os.path.relpath(path,ROOT),
                       'export_sha256':a.sha(plain)})
    INDEX.write_text(json.dumps({'format':'Club Drive audio_portable sidecar format','preview_hz':a.PREVIEW_HZ,
                                  'midi_ppq':PPQ,'assets':assets},indent=2)+'\n')
    print('Exported',len(assets),'standard WAV and MIDI files; metadata in external manifest')

def compile_native(strict=False):
    index=json.loads(INDEX.read_text())
    if index.get('format')!='Club Drive audio_portable sidecar format':raise ValueError('Bad audio_portable provenance manifest')
    indexed={r['file']:r for r in index['assets']}
    base_records=a.records()
    if set(indexed)!={r['file'] for r in base_records}:raise ValueError('Portable manifest asset set changed')
    OUT.mkdir(parents=True,exist_ok=True)
    diffs=[]
    for r in base_records:
        side=indexed[r['file']];original=_original(r)
        if side['original_sha256']!=r['sha256'] or side['native_size']!=r['size'] or side['kind']!=r['kind']:
            raise ValueError('Sidecar provenance mismatch: '+r['file'])
        file=ROOT/side['portable_file']
        if file.resolve()!=(WAV if r['kind']=='f16' else MIDI).joinpath(Path(r['file']).stem+('.wav' if r['kind']=='f16' else '.mid')).resolve():
            raise ValueError('Sidecar portable path changed: '+r['file'])
        b=file.read_bytes()
        if a.sha(b)==side['export_sha256']:
            compiled=original  # preserve original even across portable editor rewrites
        else:
            compiled=import_wav(b,original) if r['kind']=='f16' else import_midi(b,original)
        if len(compiled)!=len(original):raise ValueError('Native asset size changed: '+r['file'])
        (OUT/r['file']).write_bytes(compiled)
        if compiled!=original:
            diffs.append({'file':r['file'],'changed_bytes':sum(x!=y for x,y in zip(original,compiled))})
    manifest=json.loads(a.MANIFEST.read_text());bank=bytearray((a.REC/'SOUND_BANK.bin').read_bytes())
    start,end=manifest['bank_start'],manifest['bank_end']
    if len(bank)!=end-start:raise ValueError('Original audio bank size mismatch')
    for r in base_records:
        offset=r['rom_start']-start
        if offset<0 or offset+r['size']>len(bank):raise ValueError('Asset points beyond audio bank')
        bank[offset:offset+r['size']]=(OUT/r['file']).read_bytes()
    (OUT/'SOUND_BANK.bin').write_bytes(bank)
    report={'clean':not diffs,'edited_assets':diffs,'bank_sha256':a.sha(bank),
            'reference_bank_sha256':a.sha((a.REC/'SOUND_BANK.bin').read_bytes())}
    (ROOT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    if strict and diffs:raise ValueError(f'Expected unchanged audio, found {diffs}')
    print('Compiled 49 native assets; changed:',len(diffs),'bank SHA:',a.sha(bank))
    return report

def patch_rom(reference:Path,target:Path):
    report=compile_native()
    manifest=json.loads(a.MANIFEST.read_text())
    retail=reference.read_bytes();start,end=manifest['bank_start'],manifest['bank_end']
    if len(retail)!=2097152 or a.sha(retail)!=manifest['reference_sha256']:
        raise ValueError('Reference ROM SHA/length mismatch')
    bank=(OUT/'SOUND_BANK.bin').read_bytes()
    updated=retail[:start]+bank+retail[end:]
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(updated)
    print('Patched',target,'SHA',a.sha(updated),'retail-identical',updated==retail)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=['export','compile','check','patch-rom'])
    p.add_argument('--reference',type=Path)
    p.add_argument('--output',type=Path)
    ar=p.parse_args()
    if ar.command=='export':export()
    elif ar.command in ('compile','check'):compile_native(strict=ar.command=='check')
    else:
        if not ar.reference or not ar.output:p.error('patch-rom requires --reference and --output')
        patch_rom(ar.reference,ar.output)
if __name__=='__main__':main()
