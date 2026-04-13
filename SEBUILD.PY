"""SEBUILD.PY - Patch COLOR and SYNHI EQU values in SECONFIG.INC.

Usage: python SEBUILD.PY <color> <synhi>
  color  - 0 or 1
  synhi  - 0, 1, or 2
"""

import re
import sys

def patch_equ(filepath, name, value):
    """Replace 'name EQU <old>' with 'name EQU <new>' preserving comment."""
    with open(filepath, 'r') as f:
        text = f.read()
    pattern = re.compile(
        r'^(' + re.escape(name) + r'\s+EQU\s+)\d+(\s*;.*)?$',
        re.MULTILINE
    )
    new_text, count = pattern.subn(
        lambda m: m.group(1) + str(value) + (m.group(2) or ''),
        text
    )
    if count == 0:
        print(f'WARNING: {name} EQU not found in {filepath}')
        return False
    with open(filepath, 'w') as f:
        f.write(new_text)
    return True

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    color = int(sys.argv[1])
    synhi = int(sys.argv[2])

    if color not in (0, 1):
        print(f'ERROR: color must be 0 or 1, got {color}')
        sys.exit(1)
    if synhi not in (0, 1, 2):
        print(f'ERROR: synhi must be 0, 1, or 2, got {synhi}')
        sys.exit(1)
    if synhi > 0 and color == 0:
        print(f'ERROR: highlighting requires color (color=0 synhi={synhi})')
        sys.exit(1)

    ok = True
    ok &= patch_equ('SECONFIG.INC', 'COLOR', color)
    ok &= patch_equ('SECONFIG.INC', 'SYNHI', synhi)

    labels = {(0,0): 'mono', (1,0): 'color', (1,1): 'color+ASM', (1,2): 'color+C'}
    label = labels.get((color, synhi), f'COLOR={color} SYNHI={synhi}')
    print(f'Patched SECONFIG.INC: {label}')

    if not ok:
        sys.exit(1)

if __name__ == '__main__':
    main()
