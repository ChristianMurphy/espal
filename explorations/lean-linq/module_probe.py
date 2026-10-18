"""First, mechanical step of moving lean-linq to Lean's module system.

Adds `module`, makes every import public and opens an exposed public section in each file given.
The README lists the manual steps that followed and what still failed.
"""

import pathlib
import sys

for path in map(pathlib.Path, sys.argv[1:]):
    lines = path.read_text().split("\n")
    imports = [i for i, line in enumerate(lines) if line.startswith("import ")]
    if imports:
        first, last = imports[0], imports[-1]
        public = ["public " + l if l.startswith("import ") else l for l in lines[first : last + 1]]
        lines = lines[:first] + ["module", ""] + public + ["", "@[expose] public section", ""] + lines[last + 1 :]
    else:
        lines = ["module", "", "@[expose] public section", ""] + lines
    path.write_text("\n".join(lines))
