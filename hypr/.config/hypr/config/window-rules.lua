--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
  name           = "suppress-maximize",
  match          = { class = ".*" },

  suppress_event = "maximize",
})

hl.window_rule({
  name     = "fix-xwayland-drag",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})

hl.window_rule({
  name  = "todo-scratchpad",
  match = { title = "TodoScratchpad" },

  float = true,
})

hl.window_rule({
  name    = "btop-float",
  match   = { title = "BtopFloat" },

  float   = true,
  -- size    = { 560, 360 },
  size    = { "monitor_w * 0.60", "monitor_h * 0.65" },
  center  = true,
  opacity = "1.0 override 1.0 override",
})

hl.window_rule({
  name  = "friday-scratchpad",
  -- Ghostty's Wayland app id can differ by build; the explicit title is stable.
  match = { title = "^Friday Notes$" },
  workspace = "special:friday silent",
  float = true,
  size  = { "monitor_w * 0.96", "monitor_h * 0.5" },
  move  = { "(monitor_w - window_w) / 2", "0" },
})

hl.window_rule({
  name   = "float-term",
  match  = { title = "FloatTerm" },

  float  = true,
  size   = { 650, 650 },
  center = true,
})

-- utility windows float centered (Omarchy-style)
hl.window_rule({
  name    = "float-center",
  match   = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|org.gnome.FileRoller|nwg-look|qt6ct|imv|mpv|satty)$" },

  float   = true,
  size    = { "monitor_w * 0.60", "monitor_h * 0.65" },
  center  = true,
  opacity = "1.0 override 1.0 override",
})
