#!/bin/bash
# Launch core apps with workspace assignment (lean set — all in pacman.txt)
# NOTE: since Hyprland 0.55 `hyprctl dispatch` takes Lua, not hyprlang.

hyprctl dispatch 'hl.dsp.exec_cmd("firefox", {workspace="1"})'
hyprctl dispatch 'hl.dsp.exec_cmd("ghostty", {workspace="2"})'
hyprctl dispatch 'hl.dsp.exec_cmd("ghostty -e yazi", {workspace="3"})'

# Switch to workspace 1 at the end
hyprctl dispatch 'hl.dsp.focus({workspace=1})'
