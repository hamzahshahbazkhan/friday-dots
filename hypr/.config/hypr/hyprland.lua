-- Hyprland entry point. Put settings in the small files under ./config.
local home = os.getenv("HOME")
local config = home .. "/.config/hypr/config/"

dofile(home .. "/.config/themes/current/hyprland.lua")
dofile(config .. "monitors.lua")
dofile(config .. "startup.lua")
dofile(config .. "appearance.lua")
dofile(config .. "input.lua")
dofile(config .. "keybindings.lua")
dofile(config .. "window-rules.lua")
