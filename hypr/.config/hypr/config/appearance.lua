-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  general = {
    gaps_in          = 0,
    gaps_out         = 0,

    border_size      = 0,

    resize_on_border = true,
    allow_tearing    = false,

    layout           = "master",
  },

  decoration = {
    rounding         = 0,
    rounding_power   = 0,

    active_opacity   = 0.80,
    inactive_opacity = 0.80,

    shadow           = {
      enabled      = false,
      range        = 4,
      render_power = 3,
      color        = "rgba(1a1a1aee)",
    },

    blur             = {
      enabled  = false,
      size     = 3,
      passes   = 1,
      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = false,
  },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Keep window and workspace changes immediate; disable fades and slides.
hl.animation({ leaf = "global", enabled = false })

hl.config({
  dwindle = {
    preserve_split = true,
  },
})

hl.config({
  master = {
    new_status = "master",
  },
})

hl.config({
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo   = true,
  },
})
