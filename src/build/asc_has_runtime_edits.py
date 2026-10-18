#!/usr/bin/env python3
"""Return success when original runtime car vertex coordinates were edited.
2026 reconstruction; compares native authoring JSON with original templates.
A models PNG-only build would omit edits to play.s's runtime model includes.
"""
from pathlib import Path
import json, sys
import native_model_pipeline as mdl
for name in ('CAR2.MDL','CAR3.MDL'):
    p=Path(name)
    rows=mdl.scan(mdl.template_file(p).read_bytes().decode('latin1'),'MDL')
    original=[r['values'] for r in rows if r['group']=='vertices']
    current=[r['values'] for r in json.loads(mdl.authoring_file(p).read_text())['groups']['vertices']]
    if original!=current:
        print('Native runtime model changed:',name)
        sys.exit(0)
sys.exit(1)
