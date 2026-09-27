# Theme format

Every directory under `themes/.config/themes/` is a selectable theme. Keep
these files together so the desktop can change palettes as one unit:

| File | Used by |
| --- | --- |
| `quickshell.json` | Quickshell bar, panels, and popups |
| `hyprland.lua` | Hyprland border and accent settings |
| `hyprlock.conf` | Lock-screen colors |
| `ghostty.conf` | Ghostty terminal colors |
| `neovim.lua` | Lazy.nvim colorscheme plugin spec |
| `btop.theme`, `tmux.conf`, `zathurarc` | Terminal monitor, tmux, and PDF viewer |
| `gtk.css` | GTK 3/4 palette imported by the GTK settings |

`quickshell.json` must define eight six-digit hex colors:

```json
{
  "background": "#1d2021",
  "backgroundAlt": "#282828",
  "foreground": "#d4cfc4",
  "muted": "#7c6f64",
  "accent": "#7d8f9d",
  "accent2": "#6f8781",
  "urgent": "#d2788c",
  "border": "#3c3836"
}
```

Copy an existing theme directory, update its app palettes and `quickshell.json`,
then run `python3 scripts/build-theme-assets.py` and `./scripts/check-themes.sh`.
Select it with `theme <name>` or the launcher’s Appearance picker. Existing
terminal, Neovim, Zathura, and GTK processes may need to be reopened.
Hyprland Lua is the active compositor config on current Arch Hyprland releases.

The lock image is configured separately at
`hypr/.config/hypr/hyprlock.conf` using `$lock_background`; wallpaper cycling
does not change the lock image unless you point it at the current wallpaper.
