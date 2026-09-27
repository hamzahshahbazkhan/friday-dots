#!/bin/bash
# Move the active window with SUPER+SHIFT+arrows.
# Floating windows nudge 40px and stay put; tiled windows swap in direction.
set -u
dir="${1:-}"; [[ -n "$dir" ]] || exit 0

active="$(hyprctl activewindow -j 2>/dev/null)" || exit 0
addr="$(jq -r '.address // empty' <<<"$active")"
[[ -n "$addr" ]] || exit 0

if [[ "$(jq -r '.floating // false' <<<"$active")" == "true" ]]; then
  case "$dir" in
    left)  x=-40; y=0 ;;
    right) x=40;  y=0 ;;
    up)    x=0; y=-40 ;;
    down)  x=0; y=40 ;;
    *) exit 0 ;;
  esac
  hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", x = $x, y = $y, relative = true })" >/dev/null 2>&1
else
  hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", direction = \"$dir\" })" >/dev/null 2>&1
fi
