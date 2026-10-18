#!/usr/bin/env python3
"""car2 BND->native-MDL guardrails, Car3 lineage, and negative cases."""
import copy, json, sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'build'))
import native_bnd as bnd
from asset_paths import asset_file
import native_bnd_to_mdl as bridge
import audit_bnd_to_mdl as audit
import native_tree as tree
import native_geometry as geometry

class BndBridgeTests(unittest.TestCase):
    def old(self):return bnd.export_doc(bridge.CAR2_BND)
    def edited(self):return json.loads((bnd.BASE/'probes/CAR2_edited.geometry.json').read_text())
    def fails(self,doc):
        with self.assertRaises(ValueError):bridge.compile_car2(doc)
    def test_all_source_face_lineage(self):
        x=audit.audit()['models']
        self.assertEqual([(v['source_polygon_count'],v['runtime_polygon_count'],v['matched_geometry']) for v in x.values()],[(60,60,60),(60,59,58),(35,35,35)])
    def test_car3_nine_group_mapping_to_three_leaves(self):
        c=audit.lineage(bnd.MODELS[1]);self.assertEqual(c['runtime_tree_leaves'],3)
        self.assertEqual(len(c['source_group_to_runtime_leaf']),9)
        self.assertEqual(c['matched_cyclic_winding'],58)
    def test_car3_material_index_compaction(self):
        c=audit.lineage(bnd.MODELS[1]);s=audit.car3_findings(c)
        self.assertEqual(s['removed_source_color_index'],10)
        self.assertTrue(all(x['native_color']==x['source_color']-int(x['source_color']>10) for x in c['face_correspondence']))
    def test_car3_merges_quad_and_triangle(self):
        s=audit.audit()['car3_specific_findings']
        self.assertEqual(s['source_merged_area'],3007.0)
        self.assertEqual(s['runtime_merged_area'],3007.0)
        self.assertEqual(s['area_difference'],0)
        self.assertEqual(len(s['merged_runtime_face']['vertices']),5)
    def test_car3_normal_shift_and_replacement(self):
        s=audit.audit()['car3_specific_findings']
        self.assertEqual(s['removed_source_normal_index'],10)
        self.assertEqual(s['inserted_runtime_normal_index'],30)
        self.assertEqual(s['inserted_runtime_normal'],[0,-4874,-32402])
    def test_car3_source_groups_do_not_mean_mdls_cp_groups(self):
        c=audit.lineage(bnd.MODELS[1]);seen={p['bnd_group'] for p in c['source_group_to_runtime_leaf']}
        self.assertEqual(seen,set(range(1,9)))
        self.assertEqual({p['mdl_cp'] for p in c['source_group_to_runtime_leaf']},{1,2,3})
    def test_car2_exact_original_source_to_runtime(self):
        b,m=bridge.exact_car2_baseline()
        self.assertEqual(len(b['points']),94)
        self.assertEqual(len(m['normals']),31)
        self.assertEqual(sum(len(x['polygons']) for x in m['cp_lists']),60)
    def test_bridge_compiles_native_tree(self):
        blob,doc,stats=bridge.compile_car2(self.edited())
        native=tree.native_layout(bridge.CAR2_MDL,blob)
        self.assertEqual((native['polygons'],len(native['nodes'])),(63,3))
        self.assertEqual((stats['added_edges'],stats['cp_delta_bytes'],stats['tree_delta_bytes']),(4,34,68))
    def test_original_tables_still_prefix_generated_tables(self):
        _,doc,_=bridge.compile_car2(self.edited());base=geometry.export_doc(bridge.CAR2_MDL)
        for key in ('points','normals','dividers'):
            self.assertEqual(doc[key][:len(base[key])],base[key])
    def test_appended_BND_coordinate_rotates_about_Y(self):
        _,doc,_=bridge.compile_car2(self.edited())
        self.assertEqual(doc['points'][-1],[0,20,-36])
        self.assertEqual(doc['normals'][-1],[0,32767,0])
        self.assertEqual(doc['dividers'][-1],[94,31])
    def test_source_CP2_faces_untouched(self):
        _,doc,_=bridge.compile_car2(self.edited())
        base=geometry.export_doc(bridge.CAR2_MDL)
        self.assertEqual(doc['cp_lists'][2],base['cp_lists'][2])
    def test_generated_car2_area_conserved(self):
        _,doc,stats=bridge.compile_car2(self.edited());base=geometry.export_doc(bridge.CAR2_MDL)
        old=base['cp_lists'][1]['polygons'][0]['vertices']
        new=doc['cp_lists'][1]['polygons'][:4]
        import native_collision as c
        self.assertAlmostEqual(c.face_area(doc['points'],old),sum(c.face_area(doc['points'],f['vertices']) for f in new),places=5)
        self.assertEqual(stats['face_area_error'],0)
    def test_prototype_not_linked_into_rom(self):
        _,_,stats=bridge.compile_car2(self.edited())
        self.assertIs(stats['link_into_game'],False)
    def test_source_original_unchanged_rejected_by_bridge(self):self.fails(self.old())
    def test_append_no_fan_rejected(self):
        d=self.edited();d['cp_lists']=copy.deepcopy(self.old()['cp_lists']);self.fails(d)
    def test_wrong_appended_divider_rejected(self):
        d=self.edited();d['dividers'][-1][0]=10;self.fails(d)
    def test_existing_point_mutated_rejected(self):
        d=self.edited();d['points'][0][0]+=1;self.fails(d)
    def test_existing_normal_mutated_rejected(self):
        d=self.edited();d['normals'][0][1]+=1;self.fails(d)
    def test_existing_divider_mutated_rejected(self):
        d=self.edited();d['dividers'][0][0]+=1;self.fails(d)
    def test_two_points_appended_rejected(self):
        d=self.edited();d['points'].append([0,20,30]);self.fails(d)
    def test_two_normals_appended_rejected(self):
        d=self.edited();d['normals'].append([0,32767,0]);self.fails(d)
    def test_two_dividers_appended_rejected(self):
        d=self.edited();d['dividers'].append([94,31]);self.fails(d)
    def test_changed_other_polygon_rejected(self):
        d=self.edited();d['cp_lists'][1]['polygons'][-1]['color']^=1;self.fails(d)
    def test_change_another_cp_rejected(self):
        d=self.edited();d['cp_lists'][2]['polygons'].pop();self.fails(d)
    def test_unexpected_extra_fan_polygon_rejected(self):
        d=self.edited();d['cp_lists'][1]['polygons'].insert(1,copy.deepcopy(d['cp_lists'][1]['polygons'][1]));self.fails(d)
    def test_changed_fan_winding_rejected(self):
        d=self.edited();d['cp_lists'][1]['polygons'][0]['vertices'].reverse();self.fails(d)
    def test_wrong_fan_color_rejected(self):
        d=self.edited();d['cp_lists'][1]['polygons'][0]['color']=999;self.fails(d)
    def test_invalid_modified_geometry_plane_rejected(self):
        d=self.edited();d['points'][-1][1]+=10;self.fails(d)
    def test_wrong_source_hash_rejected(self):
        d=self.edited();d['source_template_sha256']='0'*64;self.fails(d)
    def test_modified_runtime_cp_not_auto_enabled(self):
        p=bridge.BASE/'probes/CAR2_from_BND.MDL';self.assertTrue(p.is_file())
        self.assertNotEqual(p.read_bytes(),(asset_file(bridge.CAR2_MDL)).read_bytes())
    def test_compiled_outputs_deterministic(self):
        first=bridge.compile_car2(self.edited())[0];second=bridge.compile_car2(self.edited())[0]
        self.assertEqual(first,second)
    def test_audit_manifest_reproduces(self):
        self.assertEqual(json.loads(audit.OUTPUT.read_text()),audit.audit())

if __name__=='__main__':unittest.main(verbosity=2)
