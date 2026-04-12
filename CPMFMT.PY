"""
CPMFMT.PY - Convert source files to CP/M text format.

For .MAC files:
  - Normalises line endings to CR+LF.
  - Appends a Ctrl-Z (0x1A) EOF marker.
  - INCLUDE directives are left intact for M80 to process natively.

For .INC files:
  - Normalises line endings to CR+LF.
  - Does NOT append Ctrl-Z (so M80 INCLUDE does not see a premature
    end-of-input and can return to the parent .MAC file).

Safe to run multiple times: idempotent.

Usage:
    python CPMFMT.PY          (processes all .MAC and .INC in cwd)
    python CPMFMT.PY file...  (processes named files only)
"""

import sys
import os
import glob


def normalise(data):
    """Strip CR, remove trailing Ctrl-Z, return LF-only bytes."""
    data = data.replace(b"\r\n", b"\n")
    data = data.replace(b"\r", b"\n")
    return data.rstrip(b"\x1a")


def convert(path):
    with open(path, "rb") as f:
        data = f.read()

    data = normalise(data)

    # LF -> CR+LF
    data = data.replace(b"\n", b"\r\n")

    # Append Ctrl-Z EOF marker only for .MAC files (not .INC)
    data = data.rstrip(b"\x1a")
    if not path.upper().endswith(".INC"):
        data += b"\x1a"

    with open(path, "wb") as f:
        f.write(data)

    print("Converted: " + path)


if len(sys.argv) > 1:
    targets = sys.argv[1:]
else:
    targets = glob.glob("*.MAC") + glob.glob("*.INC")

if not targets:
    print("No files found.")
else:
    for t in targets:
        if os.path.isfile(t):
            convert(t)
        else:
            print("Not found: " + t)
