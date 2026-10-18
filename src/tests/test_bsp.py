#!/usr/bin/env python3
"""Native BSP reconstruction unit tests (2026, not original Atari tests)."""
import copy, json, sys, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import bsp_authoring as bsp

class BSPTests(unittest.TestCase):
    def fixture(self,filename='CAR2.MDL'):
        rel=Path(filename)
        doc=json.loads(bsp.jpath(rel).read_text())
        src=bsp.original(rel).decode('latin1')
        nodes,cp=bsp.read_nodes(src)
        return rel,doc,nodes,cp

    def test_all_nine_unmodified_models_are_exact(self):
        for rel in bsp.MODEL_FILES:
            with self.subTest(model=str(rel)):
                doc=json.loads(bsp.jpath(rel).read_text())
                raw,stats=bsp.compile_text(rel,doc)
                self.assertEqual(raw,bsp.original(rel))
                self.assertEqual(stats['nodes'],stats['splits']*2+1)
    def test_leaf_swap_is_valid_and_changes_serialization(self):
        rel,d,*_=self.fixture()
        leaves=[v for v in d['nodes'] if v['type']=='leaf']
        leaves[0]['cp_offset'],leaves[1]['cp_offset']=leaves[1]['cp_offset'],leaves[0]['cp_offset']
        raw,stats=bsp.compile_text(rel,d)
        self.assertNotEqual(raw,bsp.original(rel))
        self.assertEqual(stats['leaves'],2)
    def test_cycle_rejected(self):
        rel,d,*_=self.fixture()
        d['nodes'][0]['first_child']=0
        with self.assertRaisesRegex(ValueError,'cycle|bad child'):bsp.compile_text(rel,d)
    def test_invalid_child_rejected(self):
        rel,d,*_=self.fixture()
        d['nodes'][0]['first_child']=8000
        with self.assertRaisesRegex(ValueError,'Bad BSP child'):bsp.compile_text(rel,d)
    def test_duplicate_cp_rejected(self):
        rel,d,*_=self.fixture()
        leaves=[v for v in d['nodes'] if v['type']=='leaf']
        leaves[1]['cp_offset']=leaves[0]['cp_offset']
        with self.assertRaisesRegex(ValueError,'cover each'):bsp.compile_text(rel,d)
    def test_bad_divider_rejected(self):
        rel,d,*_=self.fixture()
        d['nodes'][0]['divider']=999
        with self.assertRaisesRegex(ValueError,'divider'):bsp.compile_text(rel,d)
    def test_node_type_change_rejected(self):
        rel,d,*_=self.fixture()
        d['nodes'][0]['type']='leaf'
        with self.assertRaisesRegex(ValueError,'tree shape'):bsp.compile_text(rel,d)
    def test_new_negative_one_sentinel_rejected(self):
        rel,d,*_=self.fixture()
        d['nodes'][0]['divider']=-1
        with self.assertRaisesRegex(ValueError,'undocumented'):bsp.compile_text(rel,d)
    def test_template_tamper_rejected(self):
        rel,d,*_=self.fixture()
        d['source_template_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'template identity'):bsp.compile_text(rel,d)
    def test_cars_one_minus_one_sentinel_is_original(self):
        for name in ('CAR1.MDL','CAR6.MDL'):
            rel,d,nodes,cp=self.fixture(name)
            self.assertEqual(sum(n.get('divider')==-1 for n in nodes),2)
            self.assertEqual(bsp.compile_text(rel,d)[0],bsp.original(rel))

if __name__=='__main__':unittest.main(verbosity=2)
