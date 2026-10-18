#!/usr/bin/env python3
"""Club Drive audio_native: editable WAV and MIDI scores -> byte-exact F16/SCR and ROM audio bank.

The RIFF f16c chunk preserves *original* signed-magnitude bytes, including
negative zero. Changed samples are re-quantized using FullSynth's square law.
MIDI type 1 track 0 embeds native score events; track 1 presents editable note
pitch, velocity, and timing (with stable per-note markers). MIDI C4 maps to
native frequency word 206 for a useful RELATIVE-PITCH preview only.
"""
from __future__ import annotations
import argparse, hashlib, json, math, struct, wave
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REC = BASE / 'assets/native/audio/bank'
ROOT = BASE / 'assets/native/audio/authoring'
WAV = ROOT / 'wav'
MIDI = ROOT / 'midi'
COMPILED = ROOT / 'compiled'
ORIGINAL = ROOT / 'native_originals'
MANIFEST = REC / 'audio_index.json'
PREVIEW_HZ = 22050  # editor preview; native playback pitch lives in sound.s patches


def sha(b:bytes)->str: return hashlib.sha256(b).hexdigest()
def chunks(data:bytes):
    if len(data)<12 or data[:4]!=b'RIFF' or data[8:12]!=b'WAVE' or int.from_bytes(data[4:8],'little')+8 != len(data):
        raise ValueError('Not a complete RIFF/WAVE file')
    pos=12
    while pos < len(data):
        if pos+8>len(data): raise ValueError('Truncated WAVE chunk')
        id=data[pos:pos+4]; n=struct.unpack_from('<I',data,pos+4)[0];pos+=8
        if pos+n>len(data):raise ValueError('Truncated WAVE payload')
        yield id,data[pos:pos+n]
        pos+=n+(n&1)
    if pos!=len(data): raise ValueError('WAVE chunk alignment error')

def chunk(id,payload):return id+struct.pack('<I',len(payload))+payload+(b'\0' if len(payload)&1 else b'')

def decode_f16(raw:bytes)->bytes:
    # fs02_55.das: abs_byte = byte & 127; signed sample = +/- abs_byte**2
    # *2 uses most of the signed 16-bit WAV range; integer arithmetic is exact.
    return b''.join(struct.pack('<h', (-(v&127)**2 if v&128 else (v&127)**2)*2) for v in raw)

def encode_f16(pcm:bytes, original:bytes|None=None)->bytes:
    if len(pcm)&1:raise ValueError('Odd PCM byte count')
    values=struct.unpack('<'+'h'*(len(pcm)//2), pcm)
    if original is not None and len(original)!=len(values):raise ValueError('F16 length changed')
    out=bytearray()
    for i,v in enumerate(values):
        if original is not None:
            b=original[i]
            if ((-(b&127)**2 if b&128 else (b&127)**2)*2)==v:
                out.append(b);continue
        # Nearest representable native signed square-law amplitude, saturated.
        mag=min(127,max(0,int(math.floor(math.sqrt(abs(v)/2)+.5))))
        out.append(mag | (0x80 if v<0 and mag else 0))
    return bytes(out)

def wav_export(raw:bytes, filename:str)->bytes:
    pcm=decode_f16(raw)
    fmt=struct.pack('<HHIIHH',1,1,PREVIEW_HZ,PREVIEW_HZ*2,2,16)
    # Original bytes are an authoring provenance chunk, never interpreted as audio.
    private=b'CD32'+struct.pack('<I',len(raw))+bytes.fromhex(sha(pcm))+raw
    rest=b'WAVE'+chunk(b'fmt ',fmt)+chunk(b'data',pcm)+chunk(b'f16c',private)
    return b'RIFF'+struct.pack('<I',len(rest))+rest

def wav_import(blob:bytes,expected_size:int)->bytes:
    c=dict(chunks(blob))
    if b'fmt ' not in c or b'data' not in c:raise ValueError('Missing PCM chunks')
    fmt=c[b'fmt ']
    if len(fmt)<16 or struct.unpack_from('<HH',fmt)!=(1,1) or struct.unpack_from('<H',fmt,14)[0]!=16:
        raise ValueError('Expected mono, uncompressed 16-bit WAV')
    pcm=c[b'data']
    if len(pcm)!=expected_size*2:raise ValueError('WAV sample count changed; fixed ROM slot')
    original=None
    if b'f16c' in c:
        meta=c[b'f16c']
        if len(meta)<40 or meta[:4]!=b'CD32' or len(meta)!=40+expected_size or struct.unpack_from('<I',meta,4)[0]!=expected_size:
            raise ValueError('Malformed original F16 metadata')
        original=meta[40:]
        if sha(decode_f16(original))!=meta[8:40].hex():
            raise ValueError('F16 provenance check failed')
    return encode_f16(pcm,original)

def vlq(n:int)->bytes:
    if not 0<=n<0x10000000:raise ValueError('MIDI time out of range')
    a=[n&127];n>>=7
    while n:a.insert(0,(n&127)|128);n>>=7
    return bytes(a)

def read_vlq(data,pos):
    n=0
    for _ in range(4):
        if pos>=len(data):raise ValueError('Truncated MIDI VLQ')
        v=data[pos];pos+=1;n=(n<<7)|(v&127)
        if not (v&128):return n,pos
    raise ValueError('Overlong MIDI VLQ')

def trk(events):
    # Stable insertion order for events with equal tick.
    buf=bytearray();last=0
    for t,msg in events:
        if t<last:raise ValueError('Non-monotonic MIDI event ticks')
        buf.extend(vlq(t-last));buf.extend(msg);last=t
    buf.extend(b'\x00\xff\x2f\x00')
    return b'MTrk'+struct.pack('>I',len(buf))+buf

def meta(t,payload):return b'\xff'+bytes((t,))+vlq(len(payload))+payload

def mid_note(freq):
    if not freq:return 0
    return max(0,min(127,round(60+12*math.log2(freq/206))))

def native_events(scr:bytes):
    if len(scr)%8!=4 or scr[-4:]!=b'\x7f\xff\xff\xff': raise ValueError('Invalid Club Drive SCR size/terminator')
    ev=[struct.unpack_from('>II',scr,i) for i in range(0,len(scr)-4,8)]
    if any(t>t2 for (t,_),(t2,_) in zip(ev,ev[1:])):raise ValueError('Score ticks out of order')
    if any(w>>29 not in (0,3,4) for _,w in ev):raise ValueError('Unsupported native score event')
    return ev

def midi_export(scr:bytes,name:str)->bytes:
    ev=native_events(scr)
    control=[(0,meta(3,(name+' (native FullSynth events)').encode()))]
    notes=[(0,meta(3,(name+' (editable relative-pitch notes)').encode()))]
    active={}
    for i,(t,w) in enumerate(ev):
        control.append((t,meta(0x7f,b'CDR1'+struct.pack('>III',i,t,w))))
        typ=w>>29
        if typ==4:
            voice=(w>>26)&7;freq=(w>>7)&0x3fff
            note=mid_note(freq); vel=w&0x7f
            # CDX1 associates the next immediately following MIDI note with its original event.
            notes.append((t,meta(0x7f,b'CDX1'+struct.pack('>IB',i,note))))
            notes.append((t,bytes((0x90|voice,note,vel))))
            active[voice]=note
        elif typ==0:
            voice=(w>>26)&7;note=active.pop(voice,60)
            notes.append((t,meta(0x7f,b'CDX1'+struct.pack('>IB',i,note))))
            notes.append((t,bytes((0x80|voice,note,0))))
    return b'MThd'+struct.pack('>IHHH',6,1,2,480)+trk(control)+trk(notes)

def midi_tracks(data:bytes):
    if len(data)<14 or data[:4]!=b'MThd':raise ValueError('MIDI header absent')
    hlen=struct.unpack_from('>I',data,4)[0]
    fmt,track_count,division=struct.unpack_from('>HHH',data,8)
    if fmt!=1 or track_count!=2 or division!=480:raise ValueError('Expected audio_native two-track 480-PPQ MIDI')
    pos=8+hlen;result=[]
    for _ in range(track_count):
        if data[pos:pos+4]!=b'MTrk':raise ValueError('MIDI track absent')
        size=struct.unpack_from('>I',data,pos+4)[0];raw=data[pos+8:pos+8+size]
        if len(raw)!=size:raise ValueError('Truncated MIDI track')
        pos+=size+8;tick=0;idx=0;running=None;events=[]
        while idx<len(raw):
            delta,idx=read_vlq(raw,idx);tick+=delta
            status=raw[idx];
            if status<0x80:
                if running is None:raise ValueError('MIDI running status missing')
                status=running
            else:
                idx+=1
                if 0x80<=status<=0xef:running=status
                else:running=None
            if status==0xff:
                if idx>=len(raw):raise ValueError('Missing metadata tag')
                kind=raw[idx];idx+=1;size,idx=read_vlq(raw,idx)
                if idx+size>len(raw):raise ValueError('Truncated MIDI meta event')
                payload=raw[idx:idx+size];idx+=size
                events.append((tick,'meta',kind,payload))
            elif status in range(0x80,0xf0):
                n=1 if (status&0xf0) in (0xc0,0xd0) else 2
                if idx+n>len(raw):raise ValueError('Truncated MIDI channel event')
                payload=raw[idx:idx+n];idx+=n
                events.append((tick,'channel',status,payload))
            elif status in (0xf0,0xf7):
                size,idx=read_vlq(raw,idx);idx+=size
            else:raise ValueError(f'Unsupported MIDI status {status:#x}')
        result.append(events)
    if pos!=len(data):raise ValueError('Extra MIDI data')
    return result

def midi_import(data:bytes,original:bytes)->bytes:
    tracks=midi_tracks(data);baseline=native_events(original)
    raw=[]
    for tick,kind,sub,payload in tracks[0]:
        if kind=='meta' and sub==0x7f and payload.startswith(b'CDR1'):
            if len(payload)!=16:raise ValueError('Invalid CDR1 size')
            i,origin_tick,w=struct.unpack('>III',payload[4:]);raw.append([i,tick,origin_tick,w])
    if len(raw)!=len(baseline) or any(i!=n or w!=baseline[n][1] or initial_t!=baseline[n][0] for n,(i,t,initial_t,w) in enumerate(raw)):
        raise ValueError('MIDI native metadata does not match its source SCR')
    # Collect note events associated with durable CDX1 markers.
    edits={};pending=None
    for tick,kind,sub,payload in tracks[1]:
        if kind=='meta' and sub==0x7f and payload.startswith(b'CDX1'):
            if len(payload)!=9 or pending is not None:raise ValueError('Broken note marker')
            pending=struct.unpack('>IB',payload[4:])
        elif kind=='channel' and (sub&0xf0) in (0x80,0x90):
            if pending is None:raise ValueError('Unmarked MIDI note')
            i,base_note=pending;pending=None
            if i in edits or i>=len(raw):raise ValueError('Duplicate/unknown note marker')
            note,vel=payload
            edits[i]=(tick,sub,note,vel,base_note)
    if pending is not None:raise ValueError('Note without corresponding event')
    required={i for i,(_,word) in enumerate(baseline) if word>>29 in (0,4)}
    if edits.keys()!=required:raise ValueError('Missing MIDI note events')
    compiled=[];last=-1;active_notes={}
    for i,(idx,t,t_orig,w) in enumerate(raw):
        typ=w>>29
        if typ in (0,4):
            nt,status,note,velocity,orig_note=edits[i]
            voice=(w>>26)&7
            if (status&15)!=voice or ((status&0xf0)==0x90)!= (typ==4):raise ValueError('Voice/status changed incompatibly')
            if typ==4:
                if not 0<=velocity<=127:raise ValueError('Bad MIDI velocity')
                if note!=orig_note:
                    original_freq=(w>>7)&0x3fff
                    newfreq=round(original_freq*2**((note-orig_note)/12))
                    if not 1<=newfreq<=0x3fff:raise ValueError('Native pitch overflow')
                    w=(w&~(0x3fff<<7))|(newfreq<<7)
                w=(w&~0x7f)|velocity
                active_notes[voice]=note
            else:
                expected=active_notes.pop(voice,orig_note)
                if note!=expected:raise ValueError('MIDI note-off pitch must match the corresponding note-on')
            t=nt
        # Synchronize native time to editable music track and reject backwards edits.
        if t<last:raise ValueError('MIDI edits would reorder SCR events')
        compiled.append(struct.pack('>II',t,w));last=t
    result=b''.join(compiled)+b'\x7f\xff\xff\xff'
    if len(result)!=len(original):raise AssertionError('SCR byte count changed')
    return result

def records(): return json.loads(MANIFEST.read_text())['assets']

def export():
    WAV.mkdir(parents=True,exist_ok=True);MIDI.mkdir(parents=True,exist_ok=True);ORIGINAL.mkdir(parents=True,exist_ok=True)
    for r in records():
        path=REC/r['file']; archival=ORIGINAL/r['file']
        if not archival.exists(): archival.write_bytes(path.read_bytes())
        native=archival.read_bytes()
        if sha(native)!=r['sha256']:raise ValueError('Original source changed: '+r['file'])
        if r['kind']=='f16':(WAV/(path.stem+'.wav')).write_bytes(wav_export(native,path.name))
        else:(MIDI/(path.stem+'.mid')).write_bytes(midi_export(native,path.name))
    print(f'Exported {len(list(WAV.glob("*.wav")))} WAVs and {len(list(MIDI.glob("*.mid")))} MIDIs')

def compile_native(sync=False):
    COMPILED.mkdir(parents=True,exist_ok=True)
    diffs=[]
    for r in records():
        orig=(ORIGINAL/r['file']).read_bytes();fname=Path(r['file'])
        if sha(orig)!=r['sha256']:raise ValueError('Archived original hash mismatch: '+r['file'])
        p=(WAV if r['kind']=='f16' else MIDI)/(fname.stem+('.wav' if r['kind']=='f16' else '.mid'))
        new=wav_import(p.read_bytes(),r['size']) if r['kind']=='f16' else midi_import(p.read_bytes(),orig)
        if len(new)!=r['size']:raise ValueError('Resource size mismatch '+r['file'])
        if new!=orig: diffs.append({'filename':r['file'],'changed_bytes':sum(a!=b for a,b in zip(orig,new))})
        (COMPILED/r['file']).write_bytes(new)
    bank=bytearray((REC/'SOUND_BANK.bin').read_bytes())
    m=json.loads(MANIFEST.read_text());start,end=m['bank_start'],m['bank_end']
    if len(bank)!=end-start:raise ValueError('Unexpected audio bank')
    for r in records():
        pos=r['rom_start']-start;bank[pos:pos+r['size']]=(COMPILED/r['file']).read_bytes()
    (COMPILED/'SOUND_BANK.bin').write_bytes(bank)
    if sync:
        for r in records(): (REC/r['file']).write_bytes((COMPILED/r['file']).read_bytes())
        (REC/'SOUND_BANK.bin').write_bytes(bank)
    report={'samples':42,'songs':7,'changed_assets':diffs,'bank_sha256':sha(bank),'retail_bank_sha256':sha((REC/'SOUND_BANK.bin').read_bytes()) if not sync else None}
    (ROOT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Compiled',len(records()),'audio assets; changed:',len(diffs),'bank SHA:',sha(bank))
    return diffs

def rom_overlay(original_rom:Path,destination:Path):
    r=original_rom.read_bytes()
    m=json.loads(MANIFEST.read_text());
    if len(r)!=2097152 or sha(r)!=m['reference_sha256']:raise ValueError('Reference ROM mismatch')
    start,end=m['bank_start'],m['bank_end'];new=(COMPILED/'SOUND_BANK.bin').read_bytes()
    if len(new)!=end-start:raise ValueError('Unexpected compiled bank')
    patched=r[:start]+new+r[end:];destination.write_bytes(patched)
    print('ROM SHA:',sha(patched),'retail-identical:',patched==r)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=['export','compile','check','patch-rom'])
    p.add_argument('--sync-recovered',action='store_true',help='Replace original RECOVERED_AUDIO with compiled assets (backup first!)')
    p.add_argument('--reference',type=Path);p.add_argument('--output',type=Path)
    a=p.parse_args()
    if a.command=='export': export()
    elif a.command in ('compile','check'):
        diffs=compile_native(a.sync_recovered)
        if a.command=='check' and diffs:raise SystemExit('Edited audio sources detected: '+str(diffs))
    else:
        if not a.reference or not a.output:p.error('patch-rom needs --reference and --output')
        compile_native();rom_overlay(a.reference,a.output)
if __name__=='__main__':main()
