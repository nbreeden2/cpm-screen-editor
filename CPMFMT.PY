"""
CPMFMT.PY - Convert source files to CP/M text format.

For .MAC files:
  - Expands any  INCLUDE filename.ext  directives by inlining
    the content of the referenced file.  This avoids passing
    INCLUDE through M80, which terminates its input stream when
    it hits the Ctrl-Z at the end of an included file.
  - Normalises line endings to CR+LF.
  - Appends a Ctrl-Z (0x1A) EOF marker.

For .INC files:
  - Normalises line endings to CR+LF.
  - Appends Ctrl-Z.

Safe to run multiple times: idempotent.
  - After the first run the INCLUDE line has been replaced by the
    inlined content, so subsequent runs just redo CRLF + Ctrl-Z.
  - When Claude rewrites a .MAC file it restores the INCLUDE line,
    so the next run will re-expand it with the current SEDIT.INC.

Usage:
    python CPMFMT.PY          (processes all .MAC and .INC in cwd)
    python CPMFMT.PY file...  (processes named files only)
"""

import sys
import os
import glob
import re

INCLUDE_RE = re.compile(rb"^[ \t]*INCLUDE[ \t]+(\S+)", re.IGNORECASE)


def normalise(data):
    """Strip CR, remove trailing Ctrl-Z, return LF-only bytes."""
    data = data.replace(b"\r\n", b"\n")
    data = data.replace(b"\r", b"\n")
    return data.rstrip(b"\x1a")


def expand_includes(data, base_dir):
    """
    Replace every INCLUDE directive with the literal content of the
    referenced file.  Only one level of nesting is resolved.
    The included content is inserted without a trailing Ctrl-Z so
    M80's input stream continues uninterrupted into the rest of the
    parent file.
    """
    lines = data.split(b"\n")
    result = []
    for line in lines:
        m = INCLUDE_RE.match(line)
        if m:
            inc_name = m.group(1).decode("ascii", errors="replace")
            inc_path = os.path.join(base_dir, inc_name)
            if os.path.isfile(inc_path):
                with open(inc_path, "rb") as f:
                    inc_data = normalise(f.read())
                result.extend(inc_data.split(b"\n"))
                print("  Inlined:   " + inc_name)
            else:
                # Keep the line as a comment so the problem is visible
                result.append(b"; INCLUDE not found: " + inc_name.encode())
                print("  WARNING: include not found: " + inc_name)
        else:
            result.append(line)
    return b"\n".join(result)


def convert(path):
    base_dir = os.path.dirname(os.path.abspath(path))

    with open(path, "rb") as f:
        data = f.read()

    data = normalise(data)

    # Expand INCLUDE directives only in .MAC files
    if path.upper().endswith(".MAC"):
        data = expand_includes(data, base_dir)

    # LF -> CR+LF
    data = data.replace(b"\n", b"\r\n")

    # Append Ctrl-Z EOF marker
    data = data.rstrip(b"\x1a")
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
