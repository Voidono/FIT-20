#!/usr/bin/env python3
"""Rewrite the module's own res:// paths after you move it to another folder.

  python relocate.py res://games/level1/fit_runner

Scenes and resources store absolute res:// paths, so moving the folder with a file manager breaks them.
Either move it inside the Godot FileSystem dock (Godot fixes the references) or move it anywhere and run this once.
Add --from res://old/path if the module is not at the default res://minigames/fit_runner.
"""
import pathlib
import sys

args = sys.argv[1:]
old = "res://minigames/fit_runner"
if "--from" in args:
    i = args.index("--from")
    old = args[i + 1].rstrip("/")
    del args[i:i + 2]
if len(args) != 1 or not args[0].startswith("res://"):
    sys.exit(__doc__)
new = args[0].rstrip("/")
root = pathlib.Path(__file__).resolve().parent.parent
changed = 0
for path in root.rglob("*"):
    if path.suffix in {".tscn", ".tres", ".gd", ".md"} and path.is_file():
        text = path.read_text(encoding="utf-8")
        if old in text:
            path.write_text(text.replace(old, new), encoding="utf-8")
            changed += 1
print("rewrote %d files: %s -> %s" % (changed, old, new))
print("Open the project in Godot once so it re-imports; scripts that use relative preload() need no change.")
