#!/usr/bin/env python3
"""geometry collision table reconstruction: byte-exact baseline and invalid edit refusals."""
import copy
import hashlib
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import native_geometry as g
import native_collision as polygons
import native_tree as tree

class GeometryV25Tests(unittest.TestCase):
    def fixture(self):
        rel=Path('CAR2.MDL')
        return rel,g.export_doc(rel)
    def assembled_probe(self):
        return g.geometry_probe()
    def test_all_eight_unchanged_models_exact(self):
        count=0
        for rel in g.MODELS:
            with self.subTest(model=str(rel)):
                raw,stats=g.compile_text(rel,g.export_doc(rel))
                self.assertEqual(raw,tree.old.original(rel))
                count+=stats['polygons']
        self.assertEqual(count,473)
    def test_quad_probe_all_table_counts(self):
        s=self.assembled_probe()
        self.assertEqual((s['points'],s['normals'],s['dividers']), (95,32,55))
        self.assertEqual(s['polygons'],63)
        self.assertEqual(s['added_edges'],4)
        self.assertEqual(s['cp_delta_bytes'],34)
        self.assertEqual(s['new_pointers']['tree'],2436)
    def test_quad_probe_relocated_cp_leaf_and_color(self):
        s=self.assembled_probe()
        rel=Path('CAR2.MDL')
        raw=(g.BASE/'probes'/'CAR2_full_tables.MDL').read_bytes()
        lay=tree.native_layout(rel,raw)
        self.assertEqual([r['offset'] for r in lay['cp_records']],[0,2,710])
        self.assertEqual([n['cp_offset'] for n in lay['nodes'] if n['type']=='leaf'],[2,710])
        self.assertEqual(lay['header_pointers']['calculated colors']['number'],2460)
        self.assertEqual(lay['header_counts']['NUM_EDGES'],147)
    def test_quad_probe_surface_area_exact(self):
        self.assertEqual(self.assembled_probe()['probe_area_error'],0.0)
    def test_quad_probe_added_native_plane_valid(self):
        s=self.assembled_probe()
        self.assertEqual(s['new_point'],[0,20,-36])
        self.assertEqual(s['new_normal'],[0,32767,0])
        self.assertEqual(s['new_divider'],[94,31])
    def test_edited_point_within_original_plane_compiles(self):
        rel,doc=self.fixture()
        doc['points'][7][0]+=1
        raw,stats=g.compile_text(rel,doc)
        self.assertEqual(stats['changed_original_points'],1)
        self.assertNotEqual(raw,tree.old.original(rel))
        self.assertEqual(tree.native_layout(rel,raw)['header_counts']['NUM_PNTS'],94)
    def test_edited_point_out_of_plane_refused(self):
        rel,doc=self.fixture();doc['points'][7][1]+=16
        with self.assertRaisesRegex(ValueError,'plane tolerance'):
            g.compile_text(rel,doc)
    def test_changed_divider_anchor_on_same_plane(self):
        rel,doc=self.fixture();doc['dividers'][1][0]=5
        raw,stats=g.compile_text(rel,doc)
        self.assertEqual(stats['changed_original_dividers'],1)
        self.assertEqual(tree.native_layout(rel,raw)['header_counts']['NUM_DIVIDERS'],54)
    def test_redundant_split_referencing_new_divider_compiles(self):
        rel,doc=self.fixture()
        doc['dividers'].append(doc['dividers'][1][:])
        topo=tree.export_doc(rel)
        saved=topo['nodes'][0]['second']
        topo['nodes'][0]['second']='geometry_extra'
        topo['nodes'].append({'id':'geometry_extra','type':'split','divider':54,'first':None,'second':saved})
        raw,stats=g.compile_text(rel,doc,topo)
        self.assertEqual(stats['compiled_nodes'],4)
        lay=tree.native_layout(rel,raw)
        self.assertEqual(lay['nodes'][-1]['divider'],54)
    def test_incorrect_template_hash_refused(self):
        rel,doc=self.fixture();doc['source_template_sha256']='f' * 64
        with self.assertRaisesRegex(ValueError,'identity'):g.compile_text(rel,doc)
    def test_truncated_original_points_refused(self):
        rel,doc=self.fixture();doc['points'].pop()
        with self.assertRaisesRegex(ValueError,'cannot delete'):g.compile_text(rel,doc)
    def test_point_not_an_integer_refused(self):
        rel,doc=self.fixture();doc['points'][0][0]=0.5
        with self.assertRaisesRegex(ValueError,'integral'):g.compile_text(rel,doc)
    def test_point_word_overflow_refused(self):
        rel,doc=self.fixture();doc['points'][0][0]=50000
        with self.assertRaisesRegex(ValueError,'16-bit'):g.compile_text(rel,doc)
    def test_zero_normal_refused(self):
        rel,doc=self.fixture();doc['normals'][1]=[0,0,0]
        with self.assertRaisesRegex(ValueError,'unit length'):g.compile_text(rel,doc)
    def test_arbitrary_bad_normal_magnitude_refused(self):
        rel,doc=self.fixture();doc['normals'].append([1,2,3])
        with self.assertRaisesRegex(ValueError,'unit length'):g.compile_text(rel,doc)
    def test_bad_divider_point_refused(self):
        rel,doc=self.fixture();doc['dividers'].append([999,1])
        with self.assertRaisesRegex(ValueError,'index out of bounds'):g.compile_text(rel,doc)
    def test_bad_divider_normal_refused(self):
        rel,doc=self.fixture();doc['dividers'][1][1]=100000
        with self.assertRaisesRegex(ValueError,'16-bit'):g.compile_text(rel,doc)
    def test_missing_cp_list_refused(self):
        rel,doc=self.fixture();doc['cp_lists'].pop()
        with self.assertRaisesRegex(ValueError,'list count'):g.compile_text(rel,doc)
    def test_polygon_invalid_vertex_refused(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['vertices'][0]=1000
        with self.assertRaisesRegex(ValueError,'out of bounds'):g.compile_text(rel,doc)
    def test_polygon_reversed_winding_refused(self):
        rel,doc=self.fixture();f=doc['cp_lists'][1]['polygons'][0]
        f['vertices']=f['vertices'][::-1]
        with self.assertRaisesRegex(ValueError,'winding'):g.compile_text(rel,doc)
    def test_polygon_wrong_plane_refused(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['divider']=17
        with self.assertRaisesRegex(ValueError,'plane tolerance'):g.compile_text(rel,doc)
    def test_polygon_deleted_and_tree_rebased(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'].pop(0)
        raw,s=g.compile_text(rel,doc)
        self.assertEqual(s['cp_delta_bytes'],-14)
        self.assertEqual(tree.native_layout(rel,raw)['cp_records'][2]['offset'],662)
    def test_unreachable_tree_node_refused(self):
        rel,doc=self.fixture();topo=tree.export_doc(rel)
        topo['nodes'].append({'id':'unused','type':'leaf','flags':0,'cp_offset':2})
        with self.assertRaisesRegex(ValueError,'Unreachable'):g.compile_text(rel,doc,topo)
    def test_invalid_new_tree_divider_refused(self):
        rel,doc=self.fixture();topo=tree.export_doc(rel)
        topo['nodes'][0]['divider']=500
        with self.assertRaisesRegex(ValueError,'Tree divider'):g.compile_text(rel,doc,topo)
    def test_drone_unsupported(self):
        with self.assertRaisesRegex(ValueError,'Unsupported'):g.export_doc(Path('CARS/DRONE.MDL'))

if __name__=='__main__': unittest.main(verbosity=2)
