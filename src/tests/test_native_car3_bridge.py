#!/usr/bin/env python3
"""car3 Car3 source-to-native compiler and renderer/tree evidence regression tests."""
import copy
import json
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'build'))
import native_bnd as bnd
import native_collision as geom
import native_geometry as native
import native_car3_bridge as bridge
import audit_native_traversal as traversal
import native_tree as tree

class Car3BridgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source,cls.target,cls.lineage=bridge.verified_baseline()
        cls.probe=json.loads((bridge.BASE/'probes/CAR3_edited.geometry.json').read_text())
    def get(self):return copy.deepcopy(self.probe)
    def rejects(self,doc):
        with self.assertRaises(ValueError):bridge.compile_car3(doc)
    def test_known_original_lengths(self):
        self.assertEqual((len(self.source['points']),len(self.source['normals']),len(self.source['dividers'])),(90,31,40))
        self.assertEqual((len(self.target['points']),len(self.target['normals']),len(self.target['dividers'])),(90,31,40))
    def test_normal_record_removed_and_replaced(self):
        expected=[bridge.car2.rotate_y(n) for n in self.source['normals']]
        self.assertEqual(self.target['normals'][:30],expected[:10]+expected[11:])
        self.assertEqual(self.target['normals'][30],[0,-4874,-32402])
    def test_divider_table_remove_shift_append(self):
        expected=self.source['dividers'][:14]+[[p,n-int(n>10)] for p,n in self.source['dividers'][15:]]+[[12,30]]
        self.assertEqual(self.target['dividers'],expected)
    def test_merged_source_faces_preserved(self):
        self.assertEqual(len(self.lineage['unmatched_source_faces']),2)
        self.assertEqual(len(self.lineage['unmatched_runtime_faces']),1)
        self.assertEqual(self.lineage['unmatched_runtime_faces'][0]['vertices'],[21,13,6,11,2])
    def test_all_correspondences_and_original_attributes(self):
        self.assertEqual(self.lineage['matched_cyclic_winding'],58)
        self.assertEqual(self.lineage['matched_flags'],58)
    def test_material_compaction_for_all_matched_faces(self):
        for row in self.lineage['face_correspondence']:
            self.assertEqual(row['native_color'],row['source_color']-int(row['source_color']>10))
    def test_native_authoring_quad_succeeds(self):
        blob,doc,stats=bridge.compile_car3(self.get())
        result=tree.native_layout(bridge.TARGET,blob)
        self.assertEqual((result['polygons'],len(result['nodes'])),(62,5))
        self.assertEqual((stats['added_edges'],stats['cp_delta_bytes'],stats['tree_delta_bytes']),(4,34,68))
    def test_car3_probe_leaf_assignment(self):
        _,doc,stats=bridge.compile_car3(self.get())
        self.assertEqual((stats['source_group'],stats['source_index'],stats['runtime_cp'],stats['runtime_index']),(1,1,1,0))
        self.assertEqual(len(doc['cp_lists'][1]['polygons']),44)
    def test_new_point_and_normal_native_transform(self):
        _,doc,_=bridge.compile_car3(self.get())
        self.assertEqual(doc['points'][-1],[0,20,-36])
        self.assertEqual(doc['normals'][-1],[0,32767,0])
        self.assertEqual(doc['dividers'][-1],[90,31])
    def test_relocated_native_cp_offsets(self):
        blob,_,_=bridge.compile_car3(self.get())
        actual=tree.native_layout(bridge.TARGET,blob)
        self.assertEqual({x['index']:x['offset'] for x in actual['cp_records']},{0:0,1:2,2:624,3:710})
    def test_merged_native_pentagon_and_other_leaves_unchanged(self):
        _,doc,_=bridge.compile_car3(self.get())
        self.assertEqual(doc['cp_lists'][2:],self.target['cp_lists'][2:])
        self.assertIn(self.lineage['unmatched_runtime_faces'][0]['vertices'],[f['vertices'] for f in doc['cp_lists'][1]['polygons']])
    def test_original_native_arrays_are_prefixes(self):
        _,doc,_=bridge.compile_car3(self.get())
        for key in ('points','normals','dividers'):
            self.assertEqual(doc[key][:len(self.target[key])],self.target[key])
    def test_area_conservation(self):
        _,_,stats=bridge.compile_car3(self.get())
        self.assertEqual((stats['original_area'],stats['edited_area'],stats['area_error']),(13951.5,13951.5,0))
    def test_byte_identical_repeat(self):
        self.assertEqual(bridge.compile_car3(self.get())[0],bridge.compile_car3(self.get())[0])
    def test_bnd_source_redecodes(self):
        b,_=bnd.compile_text(bridge.SOURCE,self.get())
        self.assertEqual(bnd.decode(b.decode('latin1'))['points'][-1],[0,20,36])
    def test_not_linked_into_clean_rom(self):
        self.assertIs(bridge.compile_car3(self.get())[2]['link_into_game'],False)
    def test_reject_unchanged_original(self):self.rejects(copy.deepcopy(self.source))
    def test_reject_changed_existing_point(self):
        d=self.get();d['points'][0][0]+=1;self.rejects(d)
    def test_reject_changed_existing_normal(self):
        d=self.get();d['normals'][0][1]-=1;self.rejects(d)
    def test_reject_changed_existing_divider(self):
        d=self.get();d['dividers'][0][0]+=1;self.rejects(d)
    def test_reject_wrong_divider_target(self):
        d=self.get();d['dividers'][-1][1]=30;self.rejects(d)
    def test_reject_second_appended_point(self):
        d=self.get();d['points'].append([0,20,10]);self.rejects(d)
    def test_reject_second_appended_normal(self):
        d=self.get();d['normals'].append([0,32767,0]);self.rejects(d)
    def test_reject_second_appended_divider(self):
        d=self.get();d['dividers'].append([90,31]);self.rejects(d)
    def test_reject_changed_other_group(self):
        d=self.get();d['cp_lists'][2]['polygons'][0]['color']+=1;self.rejects(d)
    def test_reject_unrelated_same_group_polygon(self):
        d=self.get();d['cp_lists'][1]['polygons'][-1]['color']+=1;self.rejects(d)
    def test_reject_changed_group_ownership(self):
        d=self.get();d['cp_lists'][1]['cp_index']=2;self.rejects(d)
    def test_reject_fan_winding(self):
        d=self.get();d['cp_lists'][1]['polygons'][1]['vertices'].reverse();self.rejects(d)
    def test_reject_fan_color(self):
        d=self.get();d['cp_lists'][1]['polygons'][1]['color']+=1;self.rejects(d)
    def test_reject_fan_flags(self):
        d=self.get();d['cp_lists'][1]['polygons'][1]['flags']=0xa000;self.rejects(d)
    def test_reject_out_of_plane_added_point(self):
        d=self.get();d['points'][-1][1]+=10;self.rejects(d)
    def test_reject_reversed_normal(self):
        d=self.get();d['normals'][-1][1]*=-1;self.rejects(d)
    def test_reject_template_hash_mismatch(self):
        d=self.get();d['source_template_sha256']='0'*64;self.rejects(d)
    def test_reject_more_than_one_edited_fan(self):
        d=self.get();d['cp_lists'][1]['polygons'][10]['color']+=1;self.rejects(d)
    def test_reject_source_removed_original_face(self):
        d=self.get();d['cp_lists'][3]['polygons'].pop();self.rejects(d)
    def test_material_shift_on_second_matched_quad(self):
        """Probe independent source group 6: native material 27->26 and group 6->leaf 1."""
        d=copy.deepcopy(self.source);cp,fi=6,0
        q=d['cp_lists'][cp]['polygons'][fi];vs=q['vertices'];pts=d['points']
        p=[round((pts[vs[0]-1][i]+pts[vs[2]-1][i])/2) for i in range(3)]
        pts.append(p);raw=geom.cross(geom.sub(pts[vs[1]-1],pts[vs[0]-1]),geom.sub(pts[vs[2]-1],pts[vs[1]-1]))
        d['normals'].append([round(n*32767/geom.norm(raw)) for n in raw])
        idx=len(d['dividers']);d['dividers'].append([len(pts)-1,len(d['normals'])-1]);new=[]
        for i,v in enumerate(vs):
            f=copy.deepcopy(q);f['vertices']=[v,vs[(i+1)%4],len(pts)];f['divider']=idx;new.append(f)
        d['cp_lists'][cp]['polygons'][fi:fi+1]=new
        _,runtime,stats=bridge.compile_car3(d)
        self.assertEqual((stats['source_group'],stats['runtime_cp']),(6,1))
        self.assertEqual((q['color'],runtime['cp_lists'][stats['runtime_cp']]['polygons'][stats['runtime_index']]['color']),(27,26))
    def test_draw_tree_file_unchanged_and_grounded(self):
        report=traversal.inspect()
        self.assertEqual(len(report['models']),9)
        self.assertEqual(sum(x['nodes'] for x in report['models']),89)
        self.assertIn('Not demonstrated',report['semantics']['solid_empty_collision'])
    def test_draw_tree_car3_leaves(self):
        report=traversal.inspect()
        car=next(x for x in report['models'] if x['model']=='CARS/CAR3.MDL')
        self.assertEqual((car['nodes'],car['leaves']), (5,3))
        self.assertEqual(set(car['leaf_cp_indices']),{1,2,3})
    def test_draw_tree_manifest_reproducible(self):
        self.assertEqual(json.loads(traversal.OUTPUT.read_text()),traversal.inspect())
    def test_probe_artifacts_have_valid_redecode(self):
        path=bridge.BASE/'probes/CAR3_from_BND.MDL';self.assertTrue(path.is_file())
        self.assertEqual(tree.native_layout(bridge.TARGET,path.read_bytes())['polygons'],62)
    def test_probe_metadata_consistent(self):
        saved=json.loads((bridge.BASE/'probes/probe.json').read_text())
        self.assertEqual(saved['new_native_point'],[0,20,-36])
        self.assertEqual(saved['area_error'],0)

if __name__=='__main__':unittest.main(verbosity=2)
