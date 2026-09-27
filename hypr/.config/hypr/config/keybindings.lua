---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "thunar"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + return", hl.dsp.exec_cmd("ghostty --title=FloatTerm"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("quickshell ipc call powermenu toggle"))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.exec_cmd("quickshell ipc call keybindings open"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("quickshell ipc call wallpapers open"))
hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd("quickshell ipc call themes open"))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/utility/tmux/tmux-sessionizer.sh"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("quickshell ipc call notifications closeAll"))
hl.bind(mainMod .. " + U", hl.dsp.layout("swapwithmaster"))
hl.bind("ALT + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mainMod .. " + f", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
-- layout toggle on SHIFT+L (SUPER+L stays window navigation); arrows also focus/swap
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/layout/toggle-layout.sh"))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/move.sh left"))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/move.sh right"))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/move.sh up"))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/move.sh down"))

for i = 1, 10 do
  local key = i % 10   -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + m", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("bash " .. os.getenv("HOME") .. "/.config/scripts/utility/scratchpad.sh"))

-- resize window: equal/minus = width, SHIFT+equal/minus = height (floating stays centered)
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/resize.sh w +"))
hl.bind(mainMod .. " + minus", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/resize.sh w -"))
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/resize.sh h +"))
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/windows/resize.sh h -"))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + h", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + V",
  hl.dsp.exec_cmd("quickshell ipc call clipboard toggle"))
hl.bind(mainMod .. " + period",
  hl.dsp.exec_cmd("quickshell ipc call emoji toggle"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",
  hl.dsp.exec_cmd(
  "brightnessctl -e4 -n2 set 5%+ && quickshell ipc call osd brightness $(brightnessctl -m | cut -d, -f4 | tr -d %)"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",
  hl.dsp.exec_cmd(
  "brightnessctl -e4 -n2 set 5%- && quickshell ipc call osd brightness $(brightnessctl -m | cut -d, -f4 | tr -d %)"),
  { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("KP_Add", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))
hl.bind("KP_Subtract", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))
hl.bind("KP_Enter", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("Pause", hl.dsp.exec_cmd("playerctl play-pause"))

hl.bind(mainMod .. " + p", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/wallpaper/hyprpaper.sh"))

hl.bind(mainMod .. " + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))

hl.bind(mainMod .. " + CTRL + i", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/scripts/presets/preset1.sh"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("quickshell ipc call media toggle"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("ghostty --title=BtopFloat -e btop"))

-- reminders open the quickshell widget; alerts fire centered via quickshell
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("quickshell ipc call reminder open"))
hl.bind(mainMod .. " + CTRL + ALT + R", hl.dsp.exec_cmd("quickshell ipc call reminder open"))
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("quickshell ipc call reminder clear"))
