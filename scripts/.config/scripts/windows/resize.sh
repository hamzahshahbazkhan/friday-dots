#!/bin/bash
# Resize the active window (Omarchy-style).
#   resize.sh w +|-    grow/shrink width
#   resize.sh h +|-    grow/shrink height (pairs with SHIFT)
# Tiled windows adjust the split; floating windows resize and stay centered.
set -u

STEP=80
axis="${1:-}"; dir="${2:-}"
[[ "$axis" == "w" || "$axis" == "h" ]] || exit 0
[[ "$dir" == "+" || "$dir" == "-" ]] || exit 0

active="$(hyprctl activewindow -j 2>/dev/null)" || exit 0
addr="$(jq -r '.address // empty' <<<"$active")"
[[ -n "$addr" ]] || exit 0
floating="$(jq -r '.floating // false' <<<"$active")"

delta="$STEP"; [[ "$dir" == "-" ]] && delta="-$STEP"
if [[ "$axis" == "w" ]]; then
  x="$delta"; y=0
else
  x=0; y="$delta"
fi

hyprctl dispatch "hl.dsp.window.resize({ window = \"address:$addr\", x = $x, y = $y, relative = true })" >/dev/null 2>&1 || exit 0
if [[ "$floating" == "true" ]]; then
  hyprctl dispatch "hl.dsp.window.center({ window = \"address:$addr\" })" >/dev/null 2>&1 || true
fi
