#!/usr/bin/env python3
"""Standalone audio_native audio asset regressions: python3 tests/test_audio_roundtrip.py"""
import sys,unittest,struct,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'build'))
import audio_roundtrip as a

class AudioRoundtripTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rs=a.records()
    def test_manifest_counts(self):
        self.assertEqual(len(self.rs),49)
        self.assertEqual(sum(x['kind']=='f16' for x in self.rs),42)
        self.assertEqual(sum(x['kind']=='scr' for x in self.rs),7)
    def test_every_f16_wav_exact(self):
        for r in self.rs:
            if r['kind']!='f16':continue
            with self.subTest(r['file']):
                data=(a.ORIGINAL/r['file']).read_bytes()
                wav=(a.WAV/(Path(r['file']).stem+'.wav')).read_bytes()
                self.assertEqual(a.wav_import(wav,r['size']),data)
                self.assertEqual(a.sha(data),r['sha256'])
    def test_every_scr_midi_exact(self):
        for r in self.rs:
            if r['kind']!='scr':continue
            with self.subTest(r['file']):
                data=(a.ORIGINAL/r['file']).read_bytes()
                midi=(a.MIDI/(Path(r['file']).stem+'.mid')).read_bytes()
                self.assertEqual(a.midi_import(midi,data),data)
                self.assertEqual(a.sha(data),r['sha256'])
    def test_negative_zero_exact(self):
        src=bytes([0,0x80,1,0x81,0x7f,0xff])
        self.assertEqual(a.wav_import(a.wav_export(src,'test.f16'),len(src)),src)
        self.assertEqual(struct.unpack('<6h',a.decode_f16(src)),(0,0,2,-2,32258,-32258))
    def test_wav_edit_reencodes_one_sample(self):
        src=bytes([0,0x80,1,0x81,100,0xff]);blob=bytearray(a.wav_export(src,'test.f16'))
        data_pos=blob.index(b'data')+8
        struct.pack_into('<h',blob,data_pos+2*4,12000)
        encoded=a.wav_import(bytes(blob),len(src))
        self.assertEqual(encoded[:4],src[:4])
        self.assertNotEqual(encoded[4],src[4])
        self.assertEqual(encoded[5],src[5])
        self.assertLess(abs(struct.unpack_from('<h',a.decode_f16(encoded),8)[0]-12000),200)
    def test_wav_rejects_invalid_size(self):
        b=a.wav_export(bytes([0,1,2]),'test.f16')
        with self.assertRaises(ValueError):a.wav_import(b,4)
        with self.assertRaises(ValueError):a.wav_import(b[:-2],3)
    def test_wav_missing_provenance_still_works(self):
        original=bytes([0,1,2,25,0x81]);wav=a.wav_export(original,'test.f16')
        wav=wav[:wav.index(b'f16c')-0] # truncate chunk intentionally, repair RIFF length
        wav=wav[:4]+struct.pack('<I',len(wav)-8)+wav[8:]
        self.assertEqual(a.wav_import(wav,len(original)),original)
    def test_midi_note_edit(self):
        r=next(r for r in self.rs if r['kind']=='scr')
        scr=(a.ORIGINAL/r['file']).read_bytes(); midi=bytearray(a.midi_export(scr,r['file']))
        # Find the note status immediately after a custom event marker.
        marker=midi.index(b'CDX1')
        k=marker+9
        # One MIDI delta 0 followed by status 0x90..97, note, velocity.
        self.assertEqual(midi[k],0)
        self.assertEqual(midi[k+1]&0xf0,0x90)
        midi[k+3]=((midi[k+3]+1)&127) or 1
        result=a.midi_import(bytes(midi),scr)
        self.assertEqual(len(result),len(scr))
        self.assertEqual(sum(x!=y for x,y in zip(result,scr)),1)
    def test_midi_pitch_edit_needs_paired_note_off(self):
        r=next(r for r in self.rs if r['kind']=='scr')
        scr=(a.ORIGINAL/r['file']).read_bytes(); events=a.native_events(scr)
        midi=bytearray(a.midi_export(scr,r['file']))
        on=next(i for i,(_,w) in enumerate(events) if w>>29==4)
        voice=(events[on][1]>>26)&7
        off=next(i for i,(_,w) in enumerate(events[on+1:],start=on+1) if w>>29==0 and ((w>>26)&7)==voice)
        positions=[]
        for index in (on,off):
            m=midi.index(b'CDX1'+struct.pack('>I',index));p=m+9
            if midi[p] == 0:
                status_pos=p+1
            else:
                while midi[p]&128:p+=1
                status_pos=p+1
            self.assertEqual(midi[status_pos]&15,voice)
            positions.append(status_pos+1)
        self.assertEqual(midi[positions[0]],midi[positions[1]])
        original_freq=(events[on][1]>>7)&0x3fff
        for p in positions:midi[p]+=1
        result=a.midi_import(bytes(midi),scr)
        updated=a.native_events(result)
        newfreq=(updated[on][1]>>7)&0x3fff
        self.assertEqual(newfreq,round(original_freq*2**(1/12)))
        self.assertEqual(updated[off],events[off])

    def test_midi_rejects_missing_metadata(self):
        r=next(r for r in self.rs if r['kind']=='scr')
        original=(a.ORIGINAL/r['file']).read_bytes()
        bad=bytearray(a.midi_export(original,r['file']))
        p=bad.index(b'CDR1');bad[p:p+4]=b'XXXX'
        with self.assertRaises(ValueError):a.midi_import(bytes(bad),original)
    def test_score_terminators(self):
        for r in self.rs:
            if r['kind']=='scr':
                self.assertEqual((a.ORIGINAL/r['file']).read_bytes()[-4:],b'\x7f\xff\xff\xff')
    def test_bank_bytes_clean(self):
        self.assertEqual((a.COMPILED/'SOUND_BANK.bin').read_bytes(),(a.REC/'SOUND_BANK.bin').read_bytes())

if __name__=='__main__':unittest.main(verbosity=2)
