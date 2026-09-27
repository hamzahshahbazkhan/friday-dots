#!/usr/bin/env python3
"""Build checked-in GTK CSS palettes from each theme's quickshell.json."""
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / "themes/.config/themes"
COLOR_KEYS = ("background", "backgroundAlt", "foreground", "muted", "accent", "accent2", "urgent", "border")

for theme in sorted(ROOT.iterdir()):
    if theme.name == "current" or not theme.is_dir():
        continue
    palette = json.loads((theme / "quickshell.json").read_text())
    for key in COLOR_KEYS:
        value = palette.get(key, "")
        if not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
            raise SystemExit(f"{theme.name}: invalid or missing color {key}")
    css = f"""@define-color window_bg_color {palette['background']};
@define-color window_fg_color {palette['foreground']};
@define-color view_bg_color {palette['background']};
@define-color view_fg_color {palette['foreground']};
@define-color accent_bg_color {palette['accent']};
@define-color accent_fg_color {palette['background']};
@define-color headerbar_bg_color {palette['backgroundAlt']};
@define-color headerbar_fg_color {palette['foreground']};
@define-color card_bg_color {palette['backgroundAlt']};
@define-color borders {palette['border']};

window, dialog, popover, menu {{ background-color: @window_bg_color; color: @window_fg_color; }}
button, headerbar, .card {{ background-color: @card_bg_color; color: @window_fg_color; border-color: @borders; }}
entry, textview, treeview, list, row {{ background-color: @view_bg_color; color: @view_fg_color; }}
*:selected, selection {{ background-color: @accent_bg_color; color: @accent_fg_color; }}
tooltip {{ background-color: {palette['backgroundAlt']}; color: {palette['foreground']}; border: 1px solid {palette['border']}; }}
"""
    (theme / "gtk.css").write_text(css)
    print(f"updated {theme.name}/gtk.css")
