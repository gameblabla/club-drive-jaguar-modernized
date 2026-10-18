#!/usr/bin/env python3
"""audio_portable portable audio, sidecar integrity and controlled editor tests."""
import copy,json,struct,sys,tempfile,unittest
from collections import defaultdict
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'build'))
import audio_portable as v
import audio_roundtrip as a

class AudioPortableTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.assets=a.records()
        cls.songs=[r for r in cls.assets if r['kind']=='scr']
        cls.sounds=[r for r in cls.assets if r['kind']=='f16']
    def native(self,r):return v._original(r)
    def midi(self,r):return (v.MIDI/(Path(r['file']).stem+'.mid')).read_bytes()
    def wav(self,r):return (v.WAV/(Path(r['file']).stem+'.wav')).read_bytes()
    def midi_change(self,r,changes=None,ppq=480,drop=None,extra_channel=None):
        changes=changes or {}
        es=a.native_events(self.native(r));byvoice=defaultdict(list)
        for i,t,voice,kind,note,vel in v._voice_notes(es):
            if i==drop:continue
            t,kind,note,vel=changes.get(i,(t,kind,note,vel))
            tick=t*ppq//v.PPQ
            byvoice[voice].append((tick, bytes(((0x90 if kind=='on' else 0x80)|voice,note,vel))))
        if extra_channel is not None:
            voice=next(iter(byvoice))
            byvoice[voice].append((0,extra_channel))
            byvoice[voice].sort(key=lambda e:e[0])
        tracks=[a.trk([(0,a.meta(3,b'Portable MIDI test'))])]
        tracks.extend(a.trk(sorted(ev,key=lambda x:x[0])) for voice,ev in sorted(byvoice.items()))
        return b'MThd'+struct.pack('>IHHH',6,1,len(tracks),ppq)+b''.join(tracks)
    def test_all_42_wavs_are_standard_and_reversible(self):
        self.assertEqual(len(self.sounds),42)
        for r in self.sounds:
            with self.subTest(r['file']):
                raw=self.native(r);blob=self.wav(r)
                self.assertNotIn(b'f16c',blob)
                self.assertEqual(v.import_wav(blob,raw),raw)
    def test_all_seven_midis_are_metadata_free_and_reversible(self):
        self.assertEqual(len(self.songs),7)
        for r in self.songs:
            with self.subTest(r['file']):
                scr=self.native(r);m=self.midi(r)
                self.assertNotIn(b'CDR1',m)
                self.assertNotIn(b'CDX1',m)
                self.assertEqual(v.import_midi(m,scr),scr)
    def test_wav_edit_one_sample_and_preserve_negative_zero(self):
        r=self.sounds[0];blob=bytearray(self.wav(r));pos=blob.index(b'data')+8
        old=struct.unpack_from('<h',blob,pos)[0]
        struct.pack_into('<h',blob,pos,12000 if old!=12000 else -12000)
        original=self.native(r);edited=v.import_wav(bytes(blob),original)
        self.assertNotEqual(edited[0],original[0]);self.assertEqual(edited[1:],original[1:])
        original=bytes((0,128,1,129,127,255))
        self.assertEqual(v.import_wav(v.plain_wav(original),original),original)
    def test_wav_rejects_changed_sample_count(self):
        r=self.sounds[0]
        with self.assertRaises(ValueError):v.import_wav(self.wav(r),self.native(r)[:-1])
    def test_wav_rejects_changed_rate(self):
        r=self.sounds[0];b=bytearray(self.wav(r));p=b.index(b'fmt ')+8
        struct.pack_into('<I',b,p+4,44100)
        with self.assertRaisesRegex(ValueError,'sample rate'):v.import_wav(bytes(b),self.native(r))
    def test_native_metadata_not_embedded(self):
        r=self.songs[0]
        self.assertEqual(v.import_midi(self.midi(r),self.native(r)),self.native(r))
        for r in self.sounds:
            self.assertTrue(self.wav(r).startswith(b'RIFF'))
    def test_midi_pitch_edit_with_matching_noteoff(self):
        r=self.songs[0];original=self.native(r);notes=v._voice_notes(a.native_events(original))
        on=next(n for n in notes if n[3]=='on');off=next(n for n in notes if n[2]==on[2] and n[3]=='off' and n[0]>on[0])
        i,t,ch,k,p,vel=on;j,t2,ch2,k2,p2,vel2=off
        changes={i:(t,k,p+1,vel),j:(t2,k2,p2+1,0)}
        got=v.import_midi(self.midi_change(r,changes),original)
        orig=a.native_events(original);edited=a.native_events(got)
        self.assertEqual(len(got),len(original))
        self.assertEqual([z for z in range(len(orig)) if orig[z]!=edited[z]],[i])
        self.assertEqual((edited[i][1]>>7)&0x3fff,round(((orig[i][1]>>7)&0x3fff)*2**(1/12)))
    def test_midi_velocity_edit(self):
        r=self.songs[0];original=self.native(r)
        i,t,ch,k,n,vel=next(n for n in v._voice_notes(a.native_events(original)) if n[3]=='on')
        newvel=vel+1 if vel<127 else vel-1
        got=v.import_midi(self.midi_change(r,{i:(t,k,n,newvel)}),original)
        self.assertEqual(len(got),len(original))
        self.assertEqual(sum(x!=y for x,y in zip(got,original)),1)
    def test_midi_ppq_960_roundtrip(self):
        r=self.songs[0]
        self.assertEqual(v.import_midi(self.midi_change(r,ppq=960),self.native(r)),self.native(r))
    def test_midi_rejects_removed_note(self):
        r=self.songs[0];idx=v._voice_notes(a.native_events(self.native(r)))[0][0]
        with self.assertRaises(ValueError):v.import_midi(self.midi_change(r,drop=idx),self.native(r))
    def test_midi_rejects_wrong_noteoff_pitch(self):
        r=self.songs[0];notes=v._voice_notes(a.native_events(self.native(r)))
        off=next(n for n in notes if n[3]=='off')
        i,t,ch,kind,p,vel=off
        with self.assertRaisesRegex(ValueError,'pitch'):
            v.import_midi(self.midi_change(r,{i:(t,kind,p+1,vel)}),self.native(r))
    def test_midi_rejects_note_event_reordering(self):
        r=self.songs[0];notes=v._voice_notes(a.native_events(self.native(r)))
        on=next(n for n in notes if n[3]=='on');i,t,ch,k,n,vel=on
        # Push first note past its own off and into the next scheduled event.
        off=next(n for n in notes if n[3]=='off' and n[2]==ch and n[0]>i)
        with self.assertRaises(ValueError):v.import_midi(self.midi_change(r,{i:(off[1]+1,k,n,vel)}),self.native(r))
    def test_midi_rejects_unmappable_program_change(self):
        r=self.songs[0]
        with self.assertRaisesRegex(ValueError,'controller/program'):
            v.import_midi(self.midi_change(r,extra_channel=b'\xc0\x01'),self.native(r))
    def test_portable_manifest_sha_guards(self):
        indexed=json.loads(v.INDEX.read_text())
        self.assertEqual(indexed['format'],'Club Drive audio_portable sidecar format')
        self.assertEqual(len(indexed['assets']),49)
        for s,r in zip(indexed['assets'],self.assets):
            self.assertEqual(s['original_sha256'],r['sha256'])
    def test_bank_binary_matches_original(self):
        self.assertEqual((v.OUT/'SOUND_BANK.bin').read_bytes(),(a.REC/'SOUND_BANK.bin').read_bytes())
    def test_bank_overlay_changes_only_audio(self):
        with tempfile.TemporaryDirectory() as d:
            target=Path(d)/'rom.j64';ref=Path(__file__).resolve().parent.parent/'Club_Drive.j64'
            # Only test clean overlay if the project has its verified clean ROM.
            if not ref.exists():self.skipTest('Source ROM missing')
            v.patch_rom(ref,target)
            self.assertEqual(target.read_bytes(),ref.read_bytes())

if __name__=='__main__':unittest.main(verbosity=2)
