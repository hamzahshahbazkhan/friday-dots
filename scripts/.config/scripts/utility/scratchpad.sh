#!/usr/bin/env bash
set -euo pipefail

file="$HOME/Friday/buffer.md"
mkdir -p "$(dirname "$file")"
touch "$file"

find_scratchpad() {
  hyprctl -j clients | python3 -c '
import json, sys
for w in json.load(sys.stdin):
    title = w.get("title", "") or ""
    initial = w.get("initialTitle", "") or ""
    if "Friday Notes" in title or "Friday Notes" in initial:
        print(w.get("address", ""), w.get("workspace", {}).get("name", ""), sep="\t")
        break
'
}

# NOTE: since Hyprland 0.55 `hyprctl dispatch` takes Lua, not hyprlang.
move_to_special() {
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:friday\", window = \"address:$1\" })"
}

toggle_special() {
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("friday")'
}

# Serialize rapid presses so a slow editor startup cannot spawn duplicates.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/friday-scratchpad.lock"
flock 9

existing="$(find_scratchpad)"
if [[ -n "$existing" ]]; then
  IFS=$'\t' read -r address workspace <<< "$existing"
  if [[ "$workspace" != special:friday* ]]; then
    move_to_special "$address"
  fi
  toggle_special
  exit 0
fi

read -r -a editor_cmd <<< "${EDITOR:-nvim}"
command -v "${editor_cmd[0]}" >/dev/null 2>&1 || editor_cmd=(nvim)
# Close the lock FD (9) in the child so the editor doesn't inherit it and
# block future Super+S presses forever.
ghostty --class=FridayScratchpad --title="Friday Notes" -e "${editor_cmd[@]}" "$file" 9>&- >/dev/null 2>&1 &

# Wait for the special-workspace rule to register the window before releasing
# the lock, so a second Super+S press cannot launch another editor.
for _ in {1..50}; do
  if existing="$(find_scratchpad)" && [[ -n "$existing" ]]; then
    IFS=$'\t' read -r address workspace <<< "$existing"
    if [[ "$workspace" != special:friday* ]]; then
      move_to_special "$address"
    fi
    toggle_special
    exit 0
  fi
  sleep 0.1
done
