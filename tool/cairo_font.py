#!/usr/bin/env python3
"""Arabic in Cairo (V2_DECISIONS §19): every GoogleFonts.outfit(...) call in
lib/ becomes AppFonts.outfit(...), which uses Cairo when the app is in Arabic
(Outfit has no Arabic letters). Safe to run again; after a merge conflict keep
your own version of the file and re-run:

    python3 tool/cairo_font.py
"""
import os
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent / "lib"
HELPER = ROOT / "utils" / "app_fonts.dart"
GF_IMPORT = "import 'package:google_fonts/google_fonts.dart';"

changed = 0
for path in ROOT.rglob("*.dart"):
    if path == HELPER:
        continue
    text = path.read_text(encoding="utf-8")
    if "GoogleFonts.outfit(" not in text:
        continue
    count = text.count("GoogleFonts.outfit(")
    text = text.replace("GoogleFonts.outfit(", "AppFonts.outfit(")
    rel = os.path.relpath(HELPER, path.parent).replace(os.sep, "/")
    imp = f"import '{rel}';"
    if imp not in text:
        # After the last import line.
        imports = list(re.finditer(r"^import .*?;\s*$", text, re.M))
        at = imports[-1].end() if imports else 0
        text = text[:at] + "\n" + imp + text[at:]
    if "GoogleFonts." not in text:
        text = text.replace(GF_IMPORT + "\n", "")
    path.write_text(text, encoding="utf-8")
    changed += count
print(f"{changed} font calls now use AppFonts.outfit")
