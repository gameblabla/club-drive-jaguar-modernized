#!/usr/bin/env python3
"""Regression and negative cases for bnd intermediate BND source compiler."""
import copy, hashlib, json, sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'build'))
from asset_paths import asset_file
import native_bnd as bnd
import native_collision as geometry

class NativeBndTests(unittest.TestCase):
    def doc(self,i=0):return bnd.export_doc(bnd.MODELS[i])
    def invalid(self,doc,rel=None):
        with self.assertRaises(ValueError):bnd.compile_text(rel or bnd.MODELS[0],doc)

    def test_round_trip_all_three_exact_bytes(self):
        for rel in bnd.MODELS:
            doc=bnd.export_doc(rel)
            blob,stats=bnd.compile_text(rel,doc)
            self.assertEqual(blob,(asset_file(rel)).read_bytes())
            self.assertFalse(stats['changed'])

    def test_source_digests_match(self):
        for rel in bnd.MODELS:
            self.assertEqual(hashlib.sha256((asset_file(rel)).read_bytes()).hexdigest(),self.doc(bnd.MODELS.index(rel))['source_template_sha256'])

    def test_exact_CP_group_multiplicities(self):
        self.assertEqual([[len(x['polygons']) for x in self.doc(i)['cp_lists']] for i in range(3)],[[0,48,12,0],[0,18,1,12,1,7,7,7,7],[0,30,5]])

    def test_source_BND_to_MDL_vertex_transform_all_three(self):
        import native_model_pipeline as model
        for rel in bnd.MODELS:
            source=bnd.decode(bnd.original(rel))['points']
            target=rel.with_suffix('.MDL')
            parsed=model.scan((asset_file(target)).read_text(),'MDL')
            points=[r['values'] for r in parsed if r['group']=='vertices']
            self.assertEqual([[-p[0],p[1],-p[2]] for p in source],points)

    def test_BND_normal_transform_two_of_three(self):
        import native_model_pipeline as model
        for i in (0,2):
            rel=bnd.MODELS[i];normals=self.doc(i)['normals']
            mdl=[r['values'] for r in model.scan((asset_file(rel.with_suffix('.MDL'))).read_text(),'MDL') if r['group']=='normals']
            self.assertEqual([[-p[0],p[1],-p[2]] for p in normals],mdl)

    def test_CAR3_has_real_normal_table_difference(self):
        import native_model_pipeline as model
        rel=bnd.MODELS[1];n=self.doc(1)['normals']
        target=[r['values'] for r in model.scan((asset_file(rel.with_suffix('.MDL'))).read_text(),'MDL') if r['group']=='normals']
        self.assertNotEqual([[-p[0],p[1],-p[2]] for p in n],target)

    def test_fan_probe_area_counts_and_decode(self):
        s=bnd.probe();self.assertEqual(s['area_difference'],0)
        self.assertEqual((s['points'],s['normals'],s['dividers'],s['new_edges'],s['polygons']),(95,32,55,4,63))
        rebuilt=bnd.decode((bnd.BASE/'probes/CAR2_edited.BND').read_bytes().decode('latin1'))
        self.assertEqual([len(x['polygons']) for x in rebuilt['cp_lists']],[0,51,12,0])

    def test_original_geometry_plane_valid_for_all(self):
        for rel in bnd.MODELS:
            doc=bnd.export_doc(rel);stats=bnd.validate(rel,doc)
            self.assertGreater(stats['polygons'],0)

    def test_modified_source_hash_denied(self):
        d=self.doc();d['source_template_sha256']='0'*64;self.invalid(d)

    def test_foreign_model_denied(self):
        d=self.doc();d['source_model']='CARS/CAR3.BND';self.invalid(d)

    def test_signed_word_overflow_denied(self):
        d=self.doc();d['points'][0][0]=32768;self.invalid(d)

    def test_nonunit_normal_denied(self):
        d=self.doc();d['normals'][0]=[1,1,1];self.invalid(d)

    def test_invalid_divider_point_denied(self):
        d=self.doc();d['dividers'][0][0]=10000;self.invalid(d)

    def test_invalid_divider_normal_denied(self):
        d=self.doc();d['dividers'][0][1]=10000;self.invalid(d)

    def test_CP_group_deletion_denied(self):
        d=self.doc();d['cp_lists'].pop();self.invalid(d)

    def test_CP_group_reorder_denied(self):
        d=self.doc();d['cp_lists'][1]['cp_index']=2;self.invalid(d)

    def test_CP_nonempty_emptied_denied(self):
        d=self.doc();d['cp_lists'][1]['polygons']=[];self.invalid(d)

    def test_CP_empty_filled_denied(self):
        d=self.doc();d['cp_lists'][0]['polygons'].append(copy.deepcopy(d['cp_lists'][1]['polygons'][0]));self.invalid(d)

    def test_polygon_vertex_id_out_of_range_denied(self):
        d=self.doc();d['cp_lists'][1]['polygons'][0]['vertices'][0]=600;self.invalid(d)

    def test_polygon_winding_mismatch_denied(self):
        d=self.doc();d['cp_lists'][1]['polygons'][0]['vertices'].reverse();self.invalid(d)

    def test_repeated_vertex_denied(self):
        d=self.doc();v=d['cp_lists'][1]['polygons'][0]['vertices'];v[1]=v[0];self.invalid(d)

    def test_nonplanar_point_change_denied(self):
        d=self.doc();d['points'][4][1]+=15;self.invalid(d)

    def test_invalid_material_word_denied(self):
        d=self.doc();d['cp_lists'][1]['polygons'][0]['color']=65536;self.invalid(d)

    def test_invalid_polygon_flag_denied(self):
        d=self.doc();d['cp_lists'][1]['polygons'][0]['flags']=0x4000;self.invalid(d)

    def test_new_point_normal_divider_without_face_change(self):
        d=self.doc();d['points'].append([0,20,36]);d['normals'].append([0,32767,0]);d['dividers'].append([94,31])
        blob,stats=bnd.compile_text(bnd.MODELS[0],d)
        self.assertEqual(stats['new_edges'],0)
        self.assertEqual(bnd.decode(blob.decode('latin1'))['points'][-1],[0,20,36])

    def test_cross_format_polygon_correspondence(self):
        import audit_bnd_mdl as audit
        matches=[(audit.audit(x)['geometry_matched_polygons'],audit.audit(x)['geometry_and_flags_color_matched_polygons']) for x in bnd.MODELS]
        self.assertEqual(matches,[(60,60),(58,10),(35,35)])

    def test_CP_intermediate_counts_are_not_native_leaf_counts(self):
        import audit_bnd_mdl as audit
        a=[audit.audit(x) for x in bnd.MODELS]
        self.assertEqual([x['mdl_CP_record_count'] for x in a],[3,4,2])
        self.assertEqual([len(x['bnd_group_polygon_counts']) for x in a],[4,9,3])

    def test_BND_sizeCPsTable_disagrees_with_stream_for_two_sources(self):
        for i in (0,2):
            o=bnd.decode(bnd.original(bnd.MODELS[i]))
            self.assertNotEqual(o['sizes']['cps'],len(o['cp_lists']))

    def test_compiled_color_section_preserved(self):
        bnd.probe();rel=bnd.MODELS[0]
        orig=bnd.original(rel);edit=(bnd.BASE/'probes/CAR2_edited.BND').read_bytes().decode('latin1')
        def colors(s):
            m=bnd.decode(s)['marks'];return s[m['colors']:m['tris']]
        self.assertEqual(colors(orig),colors(edit))

if __name__=='__main__':unittest.main(verbosity=2)
