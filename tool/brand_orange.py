#!/usr/bin/env python3
"""Brand orange (C23, issue #8): use the Figma colour #FF5216 everywhere.

Replaces the old oranges 0xFFFF5E00 and 0xFFFF5722 in lib/**/*.dart with
0xFFFF5216. Safe to run again (it only changes what is still old), so after a
merge conflict keep your own version of the file and re-run:

    python3 tool/brand_orange.py
"""
import pathlib
import re

OLD = re.compile(r"0x([Ff]{2})(FF5E00|FF5722)", re.IGNORECASE)
NEW = r"0x\1FF5216"

changed = 0
for path in pathlib.Path(__file__).resolve().parent.parent.joinpath("lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    updated, count = OLD.subn(NEW, text)
    if count:
        path.write_text(updated, encoding="utf-8")
        changed += count
        print(f"{count:4d}  {path}")
print(f"{changed} colour values updated")
