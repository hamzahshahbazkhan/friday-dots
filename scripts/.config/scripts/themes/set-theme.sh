#!/usr/bin/env bash
set -euo pipefail
THEMES_DIR="$HOME/.config/themes"
THEME_LINK="$THEMES_DIR/current"

if [ -z "${1:-}" ]; then
    echo "Usage: set-theme <theme-name>"
    echo ""
    echo "Available themes:"
    ls -1 "$THEMES_DIR" 2>/dev/null | grep -v "^current$" | sed 's/^/  - /'
    [ -L "$THEME_LINK" ] && echo "" && echo "Current: $(basename "$(readlink "$THEME_LINK")")"
    exit 1
fi

THEME="$1"
[[ "$THEME" != */* && "$THEME" != .* ]] || { echo "Error: use a theme name, not a path" >&2; exit 2; }
THEME_DIR="$THEMES_DIR/$THEME"

if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Theme '$THEME' not found"
    exit 1
fi

for required in quickshell.json hyprland.lua hyprlock.conf neovim.lua gtk.css; do
    [[ -f "$THEME_DIR/$required" ]] || { echo "Error: theme '$THEME' is missing $required" >&2; exit 2; }
done
python -m json.tool "$THEME_DIR/quickshell.json" >/dev/null || { echo "Error: invalid quickshell.json in '$THEME'" >&2; exit 2; }

tmp_link="$THEMES_DIR/.current.$$"
trap 'rm -f "$tmp_link"' EXIT
ln -sfnT "$THEME_DIR" "$tmp_link"
mv -Tf "$tmp_link" "$THEME_LINK"

echo "✓ Switched to: $THEME"
echo ""
echo "Reloading..."

# Hyprland border colors come from the theme file; reload to pick them up
hyprctl reload &>/dev/null && echo "  ✓ Hyprland reloaded" || echo "  ! Hyprland reload failed (not running?)"

# Restart Quickshell so every widget reads the new theme through the current symlink.
if quickshell list 2>/dev/null | grep -q quickshell; then
    quickshell kill >/dev/null 2>&1 || true
    quickshell --daemonize
    echo "  ✓ Quickshell restarted"
fi

# tmux theme
if command -v tmux &>/dev/null && tmux info &>/dev/null 2>&1; then
    tmux source-file ~/.tmux.conf &>/dev/null && echo "  ✓ Tmux reloaded"
fi

echo ""
echo "Existing Ghostty, Neovim, and GTK app sessions may need reopening."
