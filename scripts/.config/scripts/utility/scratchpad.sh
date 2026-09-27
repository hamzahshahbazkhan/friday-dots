#!/usr/bin/env bash
set -euo pipefail

file="$HOME/Friday/buffer.md"
mkdir -p "$(dirname "$file")"
touch "$file"

find_scratchpad() {
  hyprctl -j clients | python3 -c '
import json, sys
for w in json.load(sys.stdin):
    if "Friday Notes" in (w.get("title", ""), w.get("initialTitle", "")):
        print(w.get("address", ""), w.get("workspace", {}).get("name", ""), sep="\t")
        break
'
}

# Serialize rapid presses so a slow editor startup cannot spawn duplicates.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/friday-scratchpad.lock"
flock 9

existing="$(find_scratchpad)"
if [[ -n "$existing" ]]; then
  IFS=$'\t' read -r address workspace <<< "$existing"
  if [[ "$workspace" != "special:friday" ]]; then
    hyprctl dispatch movetoworkspacesilent "special:friday,address:$address"
  fi
  hyprctl dispatch togglespecialworkspace friday
  exit 0
fi

read -r -a editor_cmd <<< "${EDITOR:-nvim}"
command -v "${editor_cmd[0]}" >/dev/null 2>&1 || editor_cmd=(nvim)
ghostty --class=FridayScratchpad --title="Friday Notes" -e "${editor_cmd[@]}" "$file" >/dev/null 2>&1 &

# Wait for the special-workspace rule to register the window before releasing
# the lock, so a second Super+S press cannot launch another editor.
for _ in {1..50}; do
  if existing="$(find_scratchpad)" && [[ -n "$existing" ]]; then
    IFS=$'\t' read -r address workspace <<< "$existing"
    if [[ "$workspace" != "special:friday" ]]; then
      hyprctl dispatch movetoworkspacesilent "special:friday,address:$address"
    fi
    hyprctl dispatch togglespecialworkspace friday
    exit 0
  fi
  sleep 0.1
done
