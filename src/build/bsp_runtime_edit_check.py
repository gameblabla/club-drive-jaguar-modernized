#!/usr/bin/env python3
"""Exit 0 if a play.s runtime car BSP differs from its original 1994 data."""
import json,sys
import bsp_authoring as bsp
for rel in bsp.MODEL_FILES[:6]:
    doc=json.loads(bsp.jpath(rel).read_text())
    original,_=bsp.read_nodes(bsp.original(rel).decode('latin1'))
    for a,b in zip(original,doc['nodes']):
        if a!=b:
            print('Runtime collision tree edited, forcing full source link:',rel)
            sys.exit(0)
sys.exit(1)
