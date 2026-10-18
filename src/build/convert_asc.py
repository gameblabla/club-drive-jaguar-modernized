#!/usr/bin/env python3
"""Convert 3D Studio ASCII tri-mesh source to editable OBJ/MTL + lossless JSON.

This does NOT pretend to produce the proprietary collision-tree .BND/.MDL
format. Output preserves object names, original floating-point coordinates,
triangle winding, edge-visibility flags and per-face material names.
"""
from pathlib import Path
import argparse, json, re, hashlib

ROOT=Path(__file__).resolve().parent.parent
FNUM=r'[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?'
START=re.compile(r'^Named object:\s*"([^"]+)"',re.I)
MESH=re.compile(r'Tri-mesh, Vertices:\s*(\d+)\s+Faces:\s*(\d+)',re.I)
VERT=re.compile(r'^Vertex\s+(\d+):\s+X:\s*('+FNUM+r')\s+Y:\s*('+FNUM+r')\s+Z:\s*('+FNUM+r')',re.I)
FACE=re.compile(r'^Face\s+(\d+):\s+A:(\d+)\s+B:(\d+)\s+C:(\d+)\s+AB:(\d+)\s+BC:(\d+)\s+CA:(\d+)',re.I)
MAT=re.compile(r'^Material:\s*"([^"]+)"',re.I)

def parse(src):
 objects=[];obj=None;lastface=None
 for line_num,line in enumerate(src.read_text(encoding='latin1').splitlines(),1):
  line=line.strip()
  if m:=START.match(line):
   obj={'name':m[1],'vertices':[],'faces':[], 'declared_vertices':None,'declared_faces':None}
   objects.append(obj);lastface=None
  elif obj is not None:
   if m:=MESH.search(line):obj['declared_vertices']=int(m[1]);obj['declared_faces']=int(m[2])
   elif m:=VERT.match(line):
    ix=int(m[1]);
    if ix!=len(obj['vertices']):raise ValueError(f'{src}:{line_num}: vertex #{ix}, expected {len(obj["vertices"])}')
    # Keep original decimal tokens (not float roundtrips) for exact re-export.
    obj['vertices'].append([m[2],m[3],m[4]])
   elif m:=FACE.match(line):
    ix=int(m[1]);
    if ix!=len(obj['faces']):raise ValueError(f'{src}:{line_num}: face #{ix}, expected {len(obj["faces"])}')
    lastface={'vertices':[int(m[2]),int(m[3]),int(m[4])], 'edges':[int(m[5]),int(m[6]),int(m[7])], 'material':None}
    obj['faces'].append(lastface)
   elif m:=MAT.match(line):
    if lastface is not None:lastface['material']=m[1]
 for obj in objects:
  # An ASCII 'Named object' may represent a camera or light, not a mesh.
  if obj['declared_vertices'] is None:
   if obj['vertices'] or obj['faces']:raise ValueError(f'{src}: vertices without mesh header')
   continue
  if len(obj['vertices'])!=obj['declared_vertices'] or len(obj['faces'])!=obj['declared_faces']:
   raise ValueError(f'{src}: {obj["name"]}: declared {obj["declared_vertices"]}/{obj["declared_faces"]}, read {len(obj["vertices"])}/{len(obj["faces"])}')
  for f in obj['faces']:
   if any(v>=len(obj['vertices']) for v in f['vertices']):raise ValueError(f'{src}: face index out of range')
 return objects

def safe_label(s):return re.sub('[^a-zA-Z0-9_]+','_',s).strip('_') or 'unnamed'

def export(src,folder):
 objects=parse(src)
 meshes=[o for o in objects if o['declared_vertices'] is not None]
 materials=sorted({f['material'] or 'UNSPECIFIED' for o in meshes for f in o['faces']})
 folder.mkdir(exist_ok=True,parents=True)
 obj_lines=[f'# Original file: {src.relative_to(ROOT)}', '# Coordinates copied verbatim from original 3D Studio ASCII',f'mtllib {src.stem}.mtl']
 vertex_offset=0
 for no,m in enumerate(meshes):
  obj_lines.append(f'o {safe_label(m["name"])}_{no:03d}')
  for v in m['vertices']:obj_lines.append('v '+' '.join(v))
  lastmat=None
  for f in m['faces']:
   material=f['material'] or 'UNSPECIFIED'
   if material!=lastmat:obj_lines.append('usemtl '+safe_label(material));lastmat=material
   vs=[v+1+vertex_offset for v in f['vertices']]
   obj_lines.append(f'f {vs[0]} {vs[1]} {vs[2]}')
  vertex_offset+=len(m['vertices'])
 (folder/f'{src.stem}.obj').write_text('\n'.join(obj_lines)+'\n')
 mtl=['# Materials from Club Drive original ASCII; Neutral placeholder color; original material names preserved but physical CRY colors not decoded.']
 for material in materials:
  mtl += ['newmtl '+safe_label(material), 'Kd 0.7 0.7 0.7', '# Original 1994 material name: '+material,'']
 (folder/f'{src.stem}.mtl').write_text('\n'.join(mtl))
 doc={'source':str(src.relative_to(ROOT)),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),
      'objects':objects,'material_names':materials,
      'note':'Geometry and material names preserved; not original .BND collision tree or .MDL binary.'}
 (folder/f'{src.stem}.json').write_text(json.dumps(doc,indent=1)+'\n')
 return {'file':doc['source'],'total_objects':len(objects),'mesh_count':len(meshes),
         'vertices':sum(len(m['vertices']) for m in meshes), 'triangles':sum(len(m['faces']) for m in meshes)}

def verify(src, folder):
 meshes=[m for m in parse(src) if m['declared_vertices'] is not None]
 lines=(folder/f'{src.stem}.obj').read_text().splitlines()
 n_v=sum(line.startswith('v ') for line in lines)
 n_f=sum(line.startswith('f ') for line in lines)
 assert n_v==sum(len(m['vertices']) for m in meshes)
 assert n_f==sum(len(m['faces']) for m in meshes)
 assert [line[2:] for line in lines if line.startswith('v ')]==[' '.join(v) for m in meshes for v in m['vertices']]
 assert [list(map(int,line[2:].split())) for line in lines if line.startswith('f ')]==[
  [v+1+sum(len(n['vertices']) for n in meshes[:i]) for v in f['vertices']]
  for i,m in enumerate(meshes) for f in m['faces']]

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--verify',action='store_true')
 args=ap.parse_args()
 files=sorted(p for folder in (ROOT/'assets/3d/cars',ROOT/'assets/maps/arenas',ROOT/'assets/maps/house',ROOT/'CITYWRLD',ROOT/'assets/maps/race',ROOT/'WESTWRLD')
              if folder.exists() for p in folder.iterdir() if p.suffix.upper()=='.ASC' and not p.is_symlink())
 # Avoid two archival copies of identical geometry within a folder.
 files=[p for p in files if p.is_file()]
 manifest=[];errors=[]
 for p in files:
  folder=ROOT/'assets/3d/models'/({'cars':'CARS','arenas':'ARENAS','house':'HOUSE','race':'RACEWRLD'}.get(p.parent.name.lower(),p.parent.name))
  try:
   m=export(p,folder)
   if args.verify:verify(p,folder)
   manifest.append(m)
  except Exception as exc:errors.append(f'{p.relative_to(ROOT)}: {exc}')
 total={'source_files':len(files),'converted':len(manifest),'objects':sum(m['total_objects'] for m in manifest),
        'meshes':sum(m['mesh_count'] for m in manifest),'vertices':sum(m['vertices'] for m in manifest),
        'triangles':sum(m['triangles'] for m in manifest),'errors':errors,'files':manifest}
 (ROOT/'assets/3d/models/index.json').write_text(json.dumps(total,indent=2)+'\n')
 print('Source scene conversion:',total['converted'],'/',len(files),'files;',total['meshes'],'meshes;',total['triangles'],'triangles; errors',len(errors))
 for e in errors[:15]:print('ERROR',e)
 if errors:raise SystemExit(1)
if __name__=='__main__':main()
