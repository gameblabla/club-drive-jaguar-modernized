#!/usr/bin/env python3
"""Reject case-only file aliases so the source tree also works on case-insensitive filesystems."""
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[2]


def check():
    names = defaultdict(list)
    for path in ROOT.rglob('*'):
        if path.is_file() or path.is_dir():
            names[str(path.relative_to(ROOT)).casefold()].append(path)
    dupes = [group for group in names.values() if len(group) > 1]
    if dupes:
        for group in dupes:
            print('Case-only filename collision:', *(str(p.relative_to(ROOT)) for p in group))
        raise SystemExit(f'{len(dupes)} case-only filename collisions found')
    print(f'Source path casing: PASS ({len(names)} unique files)')


if __name__ == '__main__':
    check()
