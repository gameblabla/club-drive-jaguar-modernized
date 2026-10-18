#!/usr/bin/env python3
"""Jaguar native tree variable-topology writer tests; reconstructed 2026."""
import copy
import json
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import native_tree as native

class NativeTreeV23Tests(unittest.TestCase):
    def fixture(self):
        rel=Path('CAR2.MDL')
        return rel,native.export_doc(rel)

    def with_redundant_split(self):
        rel,doc=self.fixture()
        root=doc['nodes'][0]
        old=root['second']
        root['second']='extra'
        doc['nodes'].append({'id':'extra','type':'split','divider':-1,'first':None,'second':old})
        return rel,doc

    def test_original_nine_models_are_byte_exact(self):
        total=0
        for rel in native.old.MODEL_FILES:
            with self.subTest(rel=str(rel)):
                d=native.export_doc(rel)
                output,stats=native.compile_text(rel,d)
                self.assertEqual(output,native.old.original(rel))
                self.assertEqual(stats['nodes'],stats['original_nodes'])
                self.assertEqual(stats['empty_children'],0)
                total+=stats['nodes']
        self.assertEqual(total,89)

    def test_native_polygon_offsets_and_header_byte_boundaries(self):
        rel,d=self.fixture()
        lay=native.native_layout(rel)
        self.assertEqual(lay['cp_bytes'],830)
        self.assertEqual(lay['header_pointers']['tree']['number'],2368)
        self.assertEqual(lay['header_pointers']['calculated colors']['number'],2392)
        self.assertEqual(lay['polygons'],60)
        self.assertEqual(lay['cp_map'],{0:0,2:1,676:2})

    def test_new_topology_relocates_color_table_by_exactly_eight_bytes(self):
        rel,doc=self.with_redundant_split()
        raw,stats=native.compile_text(rel,doc)
        self.assertEqual(stats['nodes'],4)
        self.assertEqual(stats['splits'],2)
        self.assertEqual(stats['leaves'],2)
        self.assertEqual(stats['empty_children'],1)
        self.assertNotEqual(raw,native.old.original(rel))
        changed=native.native_layout(rel,raw)
        self.assertEqual(changed['header_pointers']['tree']['number'],2368)
        self.assertEqual(changed['header_pointers']['calculated colors']['number'],2400)
        self.assertEqual(changed['cp_bytes'],830)
        self.assertEqual(changed['cp_map'],{0:0,2:1,676:2})
        self.assertEqual([n['offset'] for n in changed['nodes']],[0,8,16,24])
        self.assertEqual(changed['nodes'][-1]['first_child'],-1)
        self.assertEqual(changed['nodes'][-1]['second_child'],8)

    def test_reordering_nodes_recalculates_references(self):
        rel,doc=self.fixture()
        doc['nodes'][1],doc['nodes'][2]=doc['nodes'][2],doc['nodes'][1]
        raw,stats=native.compile_text(rel,doc)
        lay=native.native_layout(rel,raw)
        self.assertEqual([lay['nodes'][0][k] for k in ('first_child','second_child')],[8,16])
        self.assertEqual([lay['nodes'][i]['cp_offset'] for i in (1,2)],[676,2])
        self.assertEqual(lay['header_pointers']['calculated colors']['number'],2392)

    def test_unknown_child_and_cycle_are_rejected(self):
        rel,doc=self.fixture()
        doc['nodes'][0]['first']='absent'
        with self.assertRaisesRegex(ValueError,'Unknown native child'):
            native.compile_text(rel,doc)
        rel,doc=self.fixture()
        doc['nodes'][0]['first']=doc['nodes'][0]['id']
        with self.assertRaisesRegex(ValueError,'cycle'):
            native.compile_text(rel,doc)

    def test_leaves_must_cover_each_cp_exactly_once(self):
        rel,doc=self.fixture()
        doc['nodes'][2]['cp_offset']=doc['nodes'][1]['cp_offset']
        with self.assertRaisesRegex(ValueError,'cover each'):
            native.compile_text(rel,doc)
        rel,doc=self.fixture()
        doc['nodes'][1]['cp_offset']=0
        with self.assertRaisesRegex(ValueError,'background CP'):
            native.compile_text(rel,doc)

    def test_unapproved_leaf_flags_and_divider_rejected(self):
        rel,doc=self.fixture()
        doc['nodes'][1]['flags']=4
        with self.assertRaisesRegex(ValueError,'leaf flags'):
            native.compile_text(rel,doc)
        rel,doc=self.fixture()
        doc['nodes'][0]['divider']=40000
        with self.assertRaisesRegex(ValueError,'divider index'):
            native.compile_text(rel,doc)

    def test_tampering_native_data_or_cp_offset_is_detected(self):
        rel,doc=self.fixture()
        data=native.old.original(rel)
        broken=data.replace(b'car2_data+2392',b'car2_data+2384',1)
        with self.assertRaisesRegex(ValueError,'color table'):
            native.native_layout(rel,broken)
        broken=data.replace(b'; cpnode #2  offset 676',b'; cpnode #2  offset 674',1)
        self.assertNotEqual(broken,data)
        with self.assertRaisesRegex(ValueError,'byte count'):
            native.native_layout(rel,broken)

    def test_model_template_digest_is_enforced(self):
        rel,doc=self.fixture()
        doc['source_template_sha256']='bad digest'
        with self.assertRaisesRegex(ValueError,'identity mismatch'):
            native.compile_text(rel,doc)

    def test_original_car1_car6_and_drone_quirks_are_preserved(self):
        for name in ('CAR1.MDL','CAR6.MDL'):
            rel=Path(name)
            lay=native.native_layout(rel)
            self.assertEqual(lay['header_pointers']['tree']['number']-(lay['header_pointers']['tris']['number']+lay['cp_bytes']),2)
        drone=native.native_layout(Path('CARS/DRONE.MDL'))
        self.assertEqual(drone['header_counts']['NUM_CPS'],3)
        self.assertEqual([r['index'] for r in drone['cp_records']],[1,2])

if __name__=='__main__':unittest.main(verbosity=2)
