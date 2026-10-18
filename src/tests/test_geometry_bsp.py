#!/usr/bin/env python3
"""Independent geometry/BSP regression tests; 2026 reconstruction, not Atari."""
import copy, json, sys, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'build'))
import geometry_bsp as g
import asc_authoring as a

class GeometryTests(unittest.TestCase):
    def test_clip_spanning_triangle_keeps_area(self):
        tri=[(-1.,0.,0.),(1.,0.,0.),(0.,1.,0.)]
        a=g.clip(tri,0,0.,False);b=g.clip(tri,0,0.,True)
        self.assertTrue(a and b)
        self.assertAlmostEqual(g.area(a)+g.area(b),g.area(tri),places=10)
        self.assertTrue(all(v[0]<=1e-8 for v in a))
        self.assertTrue(all(v[0]>=-1e-8 for v in b))
    def test_coplanar_triangle(self):
        tri=[(0.,0.,0.),(0.,1.,0.),(0.,0.,1.)]
        # Coplanar surfaces are assigned by the tree's one-sided rule;
        # this low-level clip alone includes the boundary in both halves.
        self.assertEqual(g.clip(tri,0,0,False),tri)
        self.assertEqual(g.clip(tri,0,0,True),tri)
    def test_rejected_invalid_face_index(self):
        t='Named object: "bad"\nTri-mesh, Vertices: 3 Faces: 1\nVertex 0: X:0 Y:0 Z:0\nVertex 1: X:1 Y:0 Z:0\nVertex 2: X:0 Y:1 Z:0\nFace 0: A:0 B:1 C:5\n'
        with self.assertRaisesRegex(ValueError,'invalid face index'):g.read_meshes(t)
    def test_all_original_asc_counts(self):
        manifest=json.loads((g.BASE/'index.json').read_text())
        self.assertEqual(len(manifest),93)
        self.assertEqual(sum(d['faces'] for d in manifest.values()),11608)
        for d in manifest.values():self.assertLess(d['worst_relative_area_error'],1e-6)
    def test_tree_rejects_out_of_halfspace(self):
        mesh={'name':'test','vertices':[(0.,0.,0.),(3.,0.,0.),(0.,4.,0.),(5.,0.,0.),(8.,0.,0.),(5.,4.,0.)],
              'faces':[{'id':i,'indices':(j,j+1,j+2),'material':'a'} for i,j in ((0,0),(1,3))]}
        tree=g.make_tree(mesh,leaf_limit=1)
        self.assertGreater(len(tree['nodes']),1)
        self.assertEqual(g.validate_tree(tree),len(tree['nodes']))
        mutated=copy.deepcopy(tree)
        mutated['fragments'][0]['vertices'][0]=(1000.,0.,0.)
        with self.assertRaisesRegex(ValueError,'outside ancestor'):g.validate_tree(mutated)
    def test_generation_is_deterministic_and_sourced_from_json(self):
        rel=Path('CARS/CAR2.ASC')
        source=g.build(rel)
        self.assertEqual(json.loads(json.dumps(source)),json.loads(g.path(rel).read_text()))
        p=a.path_doc(rel);doc=json.loads(p.read_text());doc['vertices'][0]['xyz'][0]+=1
        changed,_,_=a.gen_asc(rel,doc)
        original,_,_=a.gen_asc(rel,json.loads(p.read_text()))
        self.assertNotEqual(original,changed)
        self.assertNotEqual(g.read_meshes(original.decode('latin1'))[0]['vertices'][0],
                            g.read_meshes(changed.decode('latin1'))[0]['vertices'][0])

if __name__=='__main__':unittest.main(verbosity=2)
