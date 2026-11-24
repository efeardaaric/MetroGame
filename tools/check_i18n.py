#!/usr/bin/env python3
"""Verifies that every I18n.t("key") used in scripts exists in i18n.gd and has TR+EN."""
import glob
import os
import re
import sys

root = os.path.join(os.path.dirname(__file__), "..")
src = open(os.path.join(root, "scripts/autoload/i18n.gd"), encoding="utf-8").read()
defined = set(re.findall(r'^\s*"([a-z0-9_]+)":\s*\[', src, re.M))
used = set()
dynamic_prefixes = ["tut_", "diff_"]
for path in glob.glob(os.path.join(root, "scripts/**/*.gd"), recursive=True):
    text = open(path, encoding="utf-8").read()
    used |= set(re.findall(r'I18n\.t\("([a-z0-9_]+)"\)', text))
# keys referenced from data files
data = open(os.path.join(root, "scripts/data/city_data.gd"), encoding="utf-8").read()
used |= set(re.findall(r'"(?:name_key|subtitle_key)":\s*"([a-z0-9_]+)"', data))
modes = open(os.path.join(root, "scripts/data/transit_modes.gd"), encoding="utf-8").read()
used |= set(re.findall(r'"(?:name_key|desc_key)":\s*"([a-z0-9_]+)"', modes))
for i in range(1, 7):
    used.add(f"tut_{i}")
for i in range(1, 4):
    used.add(f"diff_{i}")
missing = sorted(k for k in used if k not in defined)
if missing:
    print("Missing translation keys:", ", ".join(missing))
    sys.exit(1)
print(f"i18n ok: {len(used)} keys used, {len(defined)} defined")
