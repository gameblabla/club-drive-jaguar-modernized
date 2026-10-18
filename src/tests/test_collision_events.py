#!/usr/bin/env python3
"""Positive and corruption regression tests for CONTACT_EVENTS real-BIOS collision traces."""
import sys, unittest, csv, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import verify_collision_events as v

class RuntimeCollisionEvents(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with v.TRACE.open(newline='') as f:
            r=csv.DictReader(f);cls.rows=list(r)
    def changed(self,field,value,event=None):
        rows=[x.copy() for x in self.rows]
        index=next(i for i,r in enumerate(rows) if event is None or r['event']==event)
        rows[index][field]=str(value)
        with tempfile.TemporaryDirectory() as td:
            f=Path(td)/'t.csv'
            with f.open('w',newline='') as fp:
                writer=csv.DictWriter(fp,fieldnames=v.COLUMNS);writer.writeheader();writer.writerows(rows)
            with self.assertRaises(ValueError):v.analyze(f)
    def test_reference(self):self.assertEqual(v.analyze()['nonzero_committed_sequences'],2)
    def test_artifacts(self):self.assertTrue(v.verify_artifacts()['screenshots_byte_identical'])
    def test_event_count(self):self.assertEqual(v.analyze()['events'],784)
    def test_exact_gpu_address(self):self.changed('pc','0x000000')
    def test_invalid_overlay(self):self.changed('overlay','unknown')
    def test_invalid_event(self):self.changed('event','force')
    def test_bad_field(self):self.changed('field','1801')
    def test_bad_player_pointer(self):self.changed('player','0x200000')
    def test_bad_polygon_alignment(self):self.changed('polygon','0x082947')
    def test_bad_band_alignment(self):self.changed('band','0x08355E')
    def test_disabled_band(self):self.changed('band_flags','0x0001')
    def test_disabled_polygon(self):self.changed('polygon_flags','0x0044')
    def test_polygon_not_in_band(self):self.changed('polygon_in_band','0')
    def test_inconsistent_edge_count(self):self.changed('edges','9')
    def test_bad_pre_force_address(self):self.changed('force_address','0x06A240','pre_store')
    def test_bad_pre_state(self):self.changed('ram_matches','1','pre_store')
    def test_bad_post_state(self):self.changed('ram_matches','0','post_store')
    def test_unmatched_post_id(self):self.changed('event_id','9000','post_store')
    def test_bad_committed_torque(self):self.changed('tz','100','post_store')
    def test_bad_divider(self):self.changed('divider','19')
    def test_malformed_integer(self):self.changed('divider','oops')
    def test_duplicate_event_id(self):
        rows=[x.copy() for x in self.rows]
        first=next(x for x in rows if x['event']=='pre_store')
        second=next(x for x in rows if x['event']=='pre_store' and x['event_id']!=first['event_id'])
        second['event_id']=first['event_id']
        with tempfile.TemporaryDirectory() as td:
            f=Path(td)/'t.csv'
            with f.open('w',newline='') as fp:
                writer=csv.DictWriter(fp,fieldnames=v.COLUMNS);writer.writeheader();writer.writerows(rows)
            with self.assertRaises(ValueError):v.analyze(f)
    def test_native_layout_matches_source(self):
        src=(ROOT/'car.inc').read_text()
        self.assertIn('CAR_FORCE\t\tequ\tCAR_SPIN + 4',src)
        self.assertIn('CAR_TORQUE\tequ\tCAR_FORCE + 12',src)
        bnd=(ROOT/'bndhead.inc').read_text()
        self.assertIn('SURF_LIST\tEQU\tPNT_LIST+4',bnd)
    def test_baseline_geometry_no_edited_rom(self):
        self.assertEqual(v.sha(ROOT/'Club_Drive.j64') if (ROOT/'Club_Drive.j64').exists() else v.verify_artifacts()['rom_sha256'], 'dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289')

if __name__=='__main__':unittest.main(verbosity=2)
