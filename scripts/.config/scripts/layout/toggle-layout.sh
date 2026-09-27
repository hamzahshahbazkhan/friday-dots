#!/bin/bash
# Toggle Hyprland layout between master and scrolling (SUPER+L, Omarchy-style)
set -u
cur="$(hyprctl getoption general:layout 2>/dev/null | awk '/^str:/{print $2}')"
if [[ "$cur" == "scrolling" ]]; then
  hyprctl eval 'hl.config({general={layout="master"}})' >/dev/null
  notify-send "Layout" "master" -t 1500
else
  hyprctl eval 'hl.config({general={layout="scrolling"}})' >/dev/null
  notify-send "Layout" "scrolling" -t 1500
fi
