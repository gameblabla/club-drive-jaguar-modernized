#!/usr/bin/env python3
"""CONTACT_AUDIT runtime collision-source evidence and conservative collision-footprint tests."""
import copy
import json
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'build'))
import native_geometry as native
import audit_runtime_contact as contact
from asset_paths import asset_file

class ContactSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.audit=contact.inspect()
    def test_sources_present(self):
        self.assertEqual(len(self.audit['evidence']),7)
    def test_source_sha256_format(self):
        for name,meta in self.audit['evidence'].items():
            self.assertEqual(len(meta['sha256']),64,name)
    def test_collision_invoked_in_3dend(self):
        self.assertIn('include "close.gas"',contact.asset_file('3dend.gas').read_text('latin1'))
    def test_full_collision_included_from_close(self):
        self.assertIn('include "crash.gas"',contact.asset_file('close.gas').read_text('latin1'))
    def test_surface_list_not_draw_tree(self):
        self.assertEqual(self.audit['known_gates']['polygon_candidates_scanned_from'],'SURF_LIST')
        self.assertFalse(any(x['render_bsp_tree_used_for_contact'] for x in self.audit['isolated_geometry_probes']))
    def test_bit6_policies(self):
        self.assertTrue(contact.candidate(0x2000))
        self.assertFalse(contact.candidate(0x2040))
        self.assertTrue(contact.candidate(0xa000))
    def test_band_bit0_disables_contact(self):
        for f in (0x2000,0x2040,0xa000):
            self.assertFalse(contact.candidate(f,1))
            self.assertFalse(contact.candidate(f,3))
        self.assertTrue(contact.candidate(0x2000,2))
    def test_reject_invalid_flags(self):
        for flags in (-1,0x2001,0x10000,0x2000|0x4):
            with self.assertRaises(ValueError):contact.candidate(flags)
        with self.assertRaises(ValueError):contact.candidate(0x2000,-1)
        with self.assertRaises(ValueError):contact.candidate(0x2000,0x10000)
    def test_native_model_inventory(self):
        self.assertEqual(len(self.audit['original_native_models']),8)
        for entry in self.audit['original_native_models']:
            self.assertEqual(entry['eligible_when_band_enabled']+entry['skipped_by_polygon_flag6'],entry['faces'])
    def test_selected_car_models_are_eligible(self):
        for name in ('CARS/CAR2.MDL','CARS/CAR3.MDL'):
            entry=next(x for x in self.audit['original_native_models'] if x['model']==name)
            self.assertEqual(entry['skipped_by_polygon_flag6'],0)
    def test_top_level_cars_contain_ignore_collision_faces(self):
        entry=next(x for x in self.audit['original_native_models'] if x['model']=='CAR2.MDL')
        self.assertGreater(entry['skipped_by_polygon_flag6'],0)
    def test_zero_changes_to_runtime(self):
        self.assertIs(self.audit['clean_rom_modified'],False)
        for entry in self.audit['original_native_models']:
            self.assertEqual(entry['model_sha256'],contact.hashlib.sha256((asset_file(entry['model'])).read_bytes()).hexdigest())

class ContactFootprintTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original2=native.export_doc(Path('CARS/CAR2.MDL'))
        cls.edited2=json.loads((contact.ROOT/'assets/3d/conversion/car2/probes/CAR2_runtime.geometry.json').read_text())
        cls.original3=native.export_doc(Path('CARS/CAR3.MDL'))
        cls.edited3=json.loads((contact.ROOT/'assets/3d/conversion/car3/probes/CAR3_runtime.geometry.json').read_text())
    def test_both_original_vs_fan(self):
        for label,orig,edited in [('CAR2',self.original2,self.edited2),('CAR3',self.original3,self.edited3)]:
            with self.subTest(label=label):
                out=contact.fan_preview(orig,edited,1,0)
                self.assertEqual(out['sample_count'],961)
                self.assertEqual(out['footprint_disagreements'],0)
                self.assertGreater(out['inside_samples'],0)
                self.assertGreater(out['outside_samples'],0)
    def test_fan_preserves_material_and_flags(self):
        for label in ('CAR2','CAR3'):
            p=contact.probe_pair(label)
            self.assertEqual(p['fan_flags'],[p['original_flags']]*4)
            self.assertTrue(p['collision_gate_preserved'])
    def test_changed_collision_flag_rejected(self):
        modified=copy.deepcopy(self.edited2)
        modified['cp_lists'][1]['polygons'][1]['flags']=0x2040
        with self.assertRaisesRegex(ValueError,'collision flags/material'):
            contact.fan_preview(self.original2,modified,1,0)
    def test_changed_color_rejected(self):
        modified=copy.deepcopy(self.edited3)
        modified['cp_lists'][1]['polygons'][2]['color']+=1
        with self.assertRaisesRegex(ValueError,'collision flags/material'):
            contact.fan_preview(self.original3,modified,1,0)
    def test_changed_leaf_rejected(self):
        modified=copy.deepcopy(self.edited2)
        modified['cp_lists'][1]['cp_index']=2
        with self.assertRaisesRegex(ValueError,'CP ownership'):
            contact.fan_preview(self.original2,modified,1,0)
    def test_extra_unrelated_face_rejected(self):
        modified=copy.deepcopy(self.edited2)
        modified['cp_lists'][1]['polygons'].append(modified['cp_lists'][1]['polygons'][-1])
        with self.assertRaisesRegex(ValueError,'quad-to-four'):
            contact.fan_preview(self.original2,modified,1,0)
    def test_geometry_footprint_change_rejected(self):
        modified=copy.deepcopy(self.edited3)
        # Shifts the new center far to one side; changes the contact footprint.
        modified['points'][-1][0]+=1000
        with self.assertRaisesRegex(ValueError,'Collision footprint changed'):
            contact.fan_preview(self.original3,modified,1,0)
    def test_nonplanar_geometry_warning_not_physics_proof(self):
        self.assertIn('not fixed-point Jaguar',contact.probe_pair('CAR2')['limitations'])
    def test_line_contact_fixtures(self):
        for label in ('CAR2','CAR3'):
            with self.subTest(label=label):
                fixture=contact.probe_pair(label)['contact_line_fixtures']
                self.assertEqual(fixture['through_center'],{'original':True,'edited':True})
                for case in ('outside_edge','same_side','band_nocollide'):
                    self.assertEqual(fixture[case],{'original':False,'edited':False})
    def test_ignore_collision_face_does_not_contact(self):
        edited=copy.deepcopy(self.edited2)
        f=edited['cp_lists'][1]['polygons'][0]
        vertices=contact.face_point_loop(edited,f)
        center=[sum(p[j] for p in vertices)/3 for j in range(3)]
        norm=contact.cross(contact.vsub(vertices[1],vertices[0]),contact.vsub(vertices[2],vertices[0]))
        end=[center[j]+norm[j] for j in range(3)]
        start=[center[j]-norm[j] for j in range(3)]
        self.assertTrue(contact.segment_crosses_face(edited,f,start,end))
        f['flags'] |= 0x40
        self.assertFalse(contact.segment_crosses_face(edited,f,start,end))
    def test_conservative_contact_check_rejects_bad_polygon(self):
        f=copy.deepcopy(self.edited2['cp_lists'][1]['polygons'][0]);f['vertices']=[1,1,1]
        with self.assertRaisesRegex(ValueError,'Degenerate'):
            contact.segment_crosses_face(self.edited2,f,[0,0,0],[1,1,1])
    def test_probes_report_consistent(self):
        data=self.__class__
        self.assertEqual(len(contact.inspect()['isolated_geometry_probes']),2)
        self.assertEqual(json.loads(contact.REPORT.read_text()),contact.inspect())

if __name__=='__main__':unittest.main(verbosity=2)
