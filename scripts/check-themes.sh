#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/themes/.config/themes"
python3 - "$ROOT" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
required = {
    "quickshell.json", "hyprland.lua", "hyprlock.conf", "ghostty.conf",
    "neovim.lua", "btop.theme", "tmux.conf", "zathurarc", "gtk.css",
}
colors = {"background", "backgroundAlt", "foreground", "muted", "accent", "accent2", "urgent", "border"}
failed = False

for theme in sorted(p for p in root.iterdir() if p.is_dir() and p.name != "current"):
    missing = sorted(name for name in required if not (theme / name).is_file())
    errors = []
    if missing:
        errors.append("missing " + ", ".join(missing))
    try:
        data = json.loads((theme / "quickshell.json").read_text())
        absent = sorted(colors - data.keys())
        if absent:
            errors.append("missing colors " + ", ".join(absent))
        for key in colors & data.keys():
            if not isinstance(data[key], str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", data[key]):
                errors.append(f"{key} must be a six-digit hex color")
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"invalid quickshell.json: {exc}")
    if errors:
        failed = True
        print(f"FAIL {theme.name}: " + "; ".join(errors))
    else:
        print(f"OK   {theme.name}")

if failed:
    raise SystemExit(1)
PY

if command -v luac >/dev/null; then
  find "$ROOT" -mindepth 2 -maxdepth 2 -name hyprland.lua -print0 | xargs -0 -r -n1 luac -p
fi
