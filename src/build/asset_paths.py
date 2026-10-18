"""Canonical paths of surviving game resources (no staging or duplicate copies)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIRS = {
  'ARENAS': 'maps/arenas', 'RACEWRLD': 'maps/race', 'HOUSE': 'maps/house',
  'CARS': '3d/cars', 'MODELS_NATIVE': '3d/native_models',
  'GEOMETRY_SOURCE': '3d/geometry', 'GRAPHICS_SOURCE': 'graphics/artwork',
  'RECOVERED_RESOURCES': 'native/resources/packed',
  'RETAIL_DATA': 'native/resources/data',
  'RETAIL_RELEASE_CODE': 'native/rom/source',
}
ROOT_FILES = {
  **{f'CAR{i}.MDL':f'3d/native_models/root/car{i}.mdl' for i in range(1,7)},
  **{f'car{i}.mdl':f'3d/native_models/root/car{i}.mdl' for i in range(1,7)},
  'FULSYN.OJ':'native/toolchain/FULSYN.OJ',
  'fulsyn.oj':'native/toolchain/FULSYN.OJ',
  'GARAGE.REC':'native/toolchain/GARAGE.REC',
  'garage.rec':'native/toolchain/GARAGE.REC',
  'CAR.DAT':'native/resources/data/CAR.DAT',
  'car.dat':'native/resources/data/CAR.DAT',
  'youwin.cry':'native/graphics/palettes/youwin.cry',
  'score.cry':'native/graphics/palettes/score.cry',
  'dashpal.cry':'native/graphics/palettes/dashpal.cry',
  'yourit.cry':'native/graphics/palettes/yourit.cry',
}

def resolve_case(path):
    """Use the sole canonical file, including when legacy source spells its case differently."""
    if path.exists():return path
    if not path.parent.exists():return path
    matches=[p for p in path.parent.iterdir() if p.name.casefold()==path.name.casefold()]
    if len(matches)==1:return matches[0]
    return path

def asset_file(rel):
    """Return an editable/native input at its canonical location, never copy it."""
    p=Path(rel)
    if p.is_absolute():return p
    if not p.parts:return ROOT/p
    if p.parts[0]=='assets':return resolve_case(ROOT/p)
    if len(p.parts)==1 and p.name in ROOT_FILES:return resolve_case(ROOT/'assets'/ROOT_FILES[p.name])
    if p.parts[0] in DIRS:return resolve_case(ROOT/'assets'/DIRS[p.parts[0]]/Path(*p.parts[1:]))
    return resolve_case(ROOT/p)
