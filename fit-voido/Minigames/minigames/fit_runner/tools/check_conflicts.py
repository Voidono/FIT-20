#!/usr/bin/env python3
"""Check a main game project for name clashes with the FIT Runner module before you merge.

  python check_conflicts.py /path/to/main/project
"""
import pathlib
import re
import sys

if len(sys.argv) != 2:
    sys.exit(__doc__)
main = pathlib.Path(sys.argv[1]).resolve()
module = pathlib.Path(__file__).resolve().parent.parent
mine = {}
for gd in module.rglob("*.gd"):
    m = re.search(r"^class_name\s+(\w+)", gd.read_text(encoding="utf-8"), re.M)
    if m:
        mine[m.group(1)] = gd
problems = 0
for gd in main.rglob("*.gd"):
    if module in gd.parents:
        continue
    text = gd.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"^class_name\s+(\w+)", text, re.M)
    if m and m.group(1) in mine:
        print("CLASS CLASH: %s is also defined in %s" % (m.group(1), gd.relative_to(main)))
        problems += 1
settings = main / "project.godot"
if settings.exists():
    cfg = settings.read_text(encoding="utf-8", errors="ignore")
    if re.search(r"^fr_push=", cfg, re.M):
        print("note: your project already defines the fr_push action; the module will use it as is")
    for name in mine:
        if re.search(r"^%s=" % name, cfg, re.M):
            print("AUTOLOAD CLASH: %s" % name)
            problems += 1
print("checked %d module classes against %s: %d problem(s)" % (len(mine), main, problems))
