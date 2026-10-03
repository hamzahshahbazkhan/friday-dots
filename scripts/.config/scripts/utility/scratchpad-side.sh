#!/usr/bin/env bash
set -euo pipefail

file="$HOME/Friday/side.md"
mkdir -p "$(dirname "$file")"
touch "$file"

find_scratchpad() {
  hyprctl -j clients | python3 -c '
import json, sys
for w in json.load(sys.stdin):
    title = w.get("title", "") or ""
    initial = w.get("initialTitle", "") or ""
    if "Friday Side" in title or "Friday Side" in initial:
        print(w.get("address", ""), w.get("workspace", {}).get("name", ""), sep="\t")
        break
'
}

# NOTE: since Hyprland 0.55 `hyprctl dispatch` takes Lua, not hyprlang.
move_to_special() {
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:friday-side\", window = \"address:$1\" })"
}

# Snap exact right-side geometry from the focused monitor. Window-rule
# size/move expressions don't land exact pixels for terminals, so enforce
# here: ~1/5 width, full height below the 22px top bar.
ensure_geometry() {
  local addr="$1" mon_w mon_h w h x y
  read -r mon_w mon_h <<< "$(hyprctl monitors -j | python3 -c '
import json, sys
ms = json.load(sys.stdin)
m = next((m for m in ms if m.get("focused")), ms[0])
print(m["width"], m["height"])
')"
  w=$((mon_w * 20 / 100)); h=$((mon_h - 22)); x=$((mon_w - w)); y=22
  hyprctl dispatch "hl.dsp.window.resize({ window = \"address:$addr\", x = $w, y = $h })" >/dev/null
  hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", x = $x, y = $y })" >/dev/null
}

toggle_special() {
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("friday-side")'
}

# Serialize rapid presses so a slow editor startup cannot spawn duplicates.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/friday-scratchpad-side.lock"
flock 9

existing="$(find_scratchpad)"
if [[ -n "$existing" ]]; then
  IFS=$'\t' read -r address workspace <<< "$existing"
  if [[ "$workspace" != special:friday-side* ]]; then
    move_to_special "$address"
  fi
  ensure_geometry "$address"
  toggle_special
  exit 0
fi

read -r -a editor_cmd <<< "${EDITOR:-nvim}"
command -v "${editor_cmd[0]}" >/dev/null 2>&1 || editor_cmd=(nvim)
# Close the lock FD (9) in the child so the editor doesn't inherit it and
# block future presses forever.
ghostty --class=FridayScratchpad --title="Friday Side" -e "${editor_cmd[@]}" "$file" 9>&- >/dev/null 2>&1 &

# Wait for the special-workspace rule to register the window before releasing
# the lock, so a second press cannot launch another editor.
for _ in {1..50}; do
  if existing="$(find_scratchpad)" && [[ -n "$existing" ]]; then
    IFS=$'\t' read -r address workspace <<< "$existing"
    if [[ "$workspace" != special:friday-side* ]]; then
      move_to_special "$address"
    fi
    ensure_geometry "$address"
    toggle_special
    exit 0
  fi
  sleep 0.1
done
