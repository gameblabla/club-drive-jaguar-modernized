#!/usr/bin/env python3
"""2026 recovered native point/normal/divider plane conventions."""
import copy
import json
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import native_plane_audit as plane
import native_model_pipeline as mdl

class PlaneTests(unittest.TestCase):
    def test_all_twelve_native_model_planes_have_small_quantization_error(self):
        entries=[]
        for rel in mdl.manifest_paths():
            with self.subTest(model=str(rel)):
                item=plane.audit_model(rel)
                entries.append(item)
                self.assertLessEqual(item['max_plane_residual_native_units'],plane.TOLERANCE)
                self.assertEqual(item['polygon_surfaces'],
                    len(json.loads(mdl.authoring_file(rel).read_text())['groups']['surfaces']))
        self.assertEqual(len(entries),12)
        self.assertEqual(sum(e['polygon_surfaces'] for e in entries),663)
    def test_topology_preserving_bnd_and_mdl_cars_same_surface_geometry(self):
        a=plane.audit_model(Path('CARS/CAR2.BND'))
        b=plane.audit_model(Path('CARS/CAR2.MDL'))
        self.assertEqual(a['dividers'],b['dividers'])
        self.assertAlmostEqual(a['max_plane_residual_native_units'],b['max_plane_residual_native_units'])
    def test_mismatched_native_plane_is_rejected(self):
        rel=Path('CARS/CAR2.BND')
        doc=json.loads(mdl.authoring_file(rel).read_text())
        # Changing the plane associated with the first polygon violates its
        # native vertex/normal relationship even if every index stays valid.
        doc['groups']['surfaces'][0]['values'][1]=8
        with self.assertRaisesRegex(ValueError,'plane tolerance'):
            plane.audit_model(rel,doc)

if __name__=='__main__':unittest.main(verbosity=2)
