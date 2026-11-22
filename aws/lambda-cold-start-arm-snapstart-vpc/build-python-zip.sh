#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
OUT="$BASE/dist"
mkdir -p "$OUT"
rm -f "$OUT/python-handler.zip"
python3 - << PY
import zipfile
from pathlib import Path
base = Path("$BASE")
with zipfile.ZipFile(base/"dist/python-handler.zip", "w", zipfile.ZIP_DEFLATED) as z:
    z.write(base/"src/python/index.py", "index.py")
print("wrote", base/"dist/python-handler.zip")
PY
