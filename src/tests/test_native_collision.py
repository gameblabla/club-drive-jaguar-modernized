#!/usr/bin/env python3
"""polygons native CP/edge compiler regression and refusal-to-guess checks."""
import copy
import hashlib
import json
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import native_collision as nc
import native_tree as nt

class NativeCollisionV24Tests(unittest.TestCase):
    def fixture(self):
        rel=Path('CAR2.MDL')
        return rel,nc.export_doc(rel)

    def split(self):
        rel,doc=self.fixture()
        face=doc['cp_lists'][1]['polygons'][0]
        v=face['vertices'];a=copy.deepcopy(face);b=copy.deepcopy(face)
        a['vertices']=[v[0],v[1],v[2]]
        b['vertices']=[v[0],v[2],v[3]]
        doc['cp_lists'][1]['polygons'][0:1]=[a,b]
        return rel,doc

    def test_eight_no_edit_models_regenerate_exact_text(self):
        faces=0
        for rel in nc.MODELS:
            with self.subTest(model=str(rel)):
                result,stats=nc.compile_text(rel,nc.export_doc(rel))
                self.assertEqual(hashlib.sha256(result).hexdigest(),hashlib.sha256(nt.old.original(rel)).hexdigest())
                self.assertEqual(result,nt.old.original(rel))
                self.assertEqual(stats['added_edges'],0)
                faces+=stats['polygons']
        self.assertEqual(faces,473)

    def test_original_edge_bits_provide_closed_directed_loops(self):
        for rel in nc.MODELS:
            with self.subTest(model=str(rel)):
                parts=nc.original_cp(rel)
                self.assertEqual(sum(len(cp['polygons']) for cp in parts),nt.native_layout(rel)['polygons'])

    def test_split_quad_grows_edge_cp_and_tree_and_rebases_later_cp(self):
        rel,doc=self.split();binary,stats=nc.compile_text(rel,doc)
        self.assertEqual(stats['polygons'],61)
        self.assertEqual(stats['added_edges'],1)
        self.assertEqual(stats['cp_delta_bytes'],10)
        self.assertEqual(stats['tree_delta_bytes'],16)
        layout=nt.native_layout(rel,binary)
        self.assertEqual([x['offset'] for x in layout['cp_records']],[0,2,686])
        self.assertEqual([x['cp_offset'] for x in layout['nodes'] if x['type']=='leaf'],[2,686])
        self.assertEqual(layout['header_pointers']['points']['number'],792)
        self.assertEqual(layout['header_pointers']['tris']['number'],1542)
        self.assertEqual(layout['header_pointers']['end of tris']['number'],2382)
        self.assertEqual(layout['header_pointers']['tree']['number'],2384)
        self.assertEqual(layout['header_pointers']['calculated colors']['number'],2408)
        self.assertEqual(layout['header_counts']['NUM_EDGES'],144)

    def test_split_quad_exact_area_conservation(self):
        rel,doc=self.split()
        points=nc.source_geometry(rel)[1]
        original=nc.original_cp(rel)[1]['polygons'][0]['vertices']
        triangles=[p['vertices'] for p in doc['cp_lists'][1]['polygons'][:2]]
        self.assertAlmostEqual(nc.face_area(points,original),sum(nc.face_area(points,t) for t in triangles),places=7)

    def test_topology_expansion_and_polygon_split_can_be_combined(self):
        rel,doc=self.split();topo=nt.export_doc(rel)
        old=topo['nodes'][0]['second'];topo['nodes'][0]['second']='extra'
        topo['nodes'].append({'id':'extra','type':'split','divider':-1,'first':None,'second':old})
        raw,stats=nc.compile_text(rel,doc,topo)
        self.assertEqual(stats['compiled_nodes'],4)
        self.assertEqual(stats['tree_delta_bytes'],16)
        lay=nt.native_layout(rel,raw)
        self.assertEqual(lay['header_pointers']['calculated colors']['number'],2416)
        self.assertEqual(lay['nodes'][0]['second_child'],24)
        self.assertEqual(lay['nodes'][2]['cp_offset'],686)

    def test_removing_one_cp_face_shrinks_lists_and_rebases_following_leaf(self):
        rel,doc=self.fixture()
        doc['cp_lists'][1]['polygons'].pop(0)
        raw,stats=nc.compile_text(rel,doc)
        self.assertEqual(stats['polygons'],59)
        self.assertEqual(stats['added_edges'],0)
        self.assertEqual(stats['cp_delta_bytes'],-14)
        self.assertEqual(stats['tree_delta_bytes'],-12)
        lay=nt.native_layout(rel,raw)
        self.assertEqual([r['offset'] for r in lay['cp_records']],[0,2,662])
        self.assertEqual(lay['nodes'][-1]['cp_offset'],662)
        self.assertEqual(lay['header_pointers']['end of tris']['number'],2354)
        self.assertEqual(lay['header_pointers']['tree']['number'],2356)
        self.assertEqual(lay['header_pointers']['calculated colors']['number'],2380)

    def test_short_bad_vertex_list_is_rejected(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['vertices']=[1,2]
        with self.assertRaisesRegex(ValueError,'count'):nc.compile_text(rel,doc)

    def test_nonexistent_vertex_is_rejected(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['vertices'][0]=99999
        with self.assertRaisesRegex(ValueError,'out of bounds'):nc.compile_text(rel,doc)

    def test_repeated_vertex_is_rejected(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['vertices'][1]=doc['cp_lists'][1]['polygons'][0]['vertices'][0]
        with self.assertRaisesRegex(ValueError,'repeated'):nc.compile_text(rel,doc)

    def test_background_cp_must_remain_empty(self):
        rel,doc=self.fixture();doc['cp_lists'][0]['polygons'].append(copy.deepcopy(doc['cp_lists'][1]['polygons'][0]))
        with self.assertRaisesRegex(ValueError,'Background'):nc.compile_text(rel,doc)

    def test_leaf_cp_must_not_be_empty(self):
        rel,doc=self.fixture();doc['cp_lists'][2]['polygons']=[]
        with self.assertRaisesRegex(ValueError,'empty'):nc.compile_text(rel,doc)

    def test_cp_ids_must_remain_in_original_order(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['cp_index']=222
        with self.assertRaisesRegex(ValueError,'order'):nc.compile_text(rel,doc)

    def test_bad_divider_is_rejected(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['divider']=12345
        with self.assertRaisesRegex(ValueError,'divider'):nc.compile_text(rel,doc)

    def test_changed_valid_divider_to_unrelated_plane_is_rejected(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['divider']=17
        with self.assertRaisesRegex(ValueError,'plane tolerance'):nc.compile_text(rel,doc)

    def test_inverted_polygon_orientation_is_rejected(self):
        rel,doc=self.fixture()
        face=doc['cp_lists'][1]['polygons'][0]
        face['vertices']=face['vertices'][::-1]
        with self.assertRaisesRegex(ValueError,'winding'):nc.compile_text(rel,doc)

    def test_unknown_surface_flags_are_rejected(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['flags']=0x9000
        with self.assertRaisesRegex(ValueError,'flags'):nc.compile_text(rel,doc)

    def test_unverified_drone_format_is_not_silently_compiled(self):
        with self.assertRaisesRegex(ValueError,'full-header'):nc.export_doc(Path('CARS/DRONE.MDL'))

    def test_source_hash_mismatch_is_rejected(self):
        rel,doc=self.fixture();doc['source_template_sha256']='tampered'
        with self.assertRaisesRegex(ValueError,'identity mismatch'):nc.compile_text(rel,doc)

    def test_color_change_preserves_count_and_alignment(self):
        rel,doc=self.fixture();doc['cp_lists'][1]['polygons'][0]['color']=2
        raw,stats=nc.compile_text(rel,doc)
        self.assertEqual(stats['added_edges'],0)
        self.assertEqual(stats['cp_delta_bytes'],0)
        self.assertEqual(stats['tree_delta_bytes'],0)
        self.assertEqual(nt.native_layout(rel,raw)['header_pointers']['tree']['number'],2368)

if __name__=='__main__':unittest.main(verbosity=2)
