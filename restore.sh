#!/bin/bash
# restore.sh — (re)link all dots with GNU stow. No sudo needed.
# Usage: ./restore.sh [--theme <name>]
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="${1:-}"
if [[ "${1:-}" == "--theme" ]]; then THEME="${2:-}"; fi
THEME="${THEME:-hamza}"
if [[ ! -d "$DOTDIR/themes/.config/themes/$THEME" ]]; then
  echo "error: theme '$THEME' does not exist under themes/.config/themes" >&2
  exit 2
fi

# Quickshell supplies the bar, launcher, notifications, and OSD.
PACKAGES=(
  applications
  bash
  btop
  ghostty
  gtk
  hypr
  nvim
  qt6ct
  quickshell
  scripts
  themes
  thunar
  tmux
  wallpapers
  yazi
  zathura
  zsh
)

command -v stow >/dev/null || { echo "error: stow not installed (run ./bootstrap.sh first)"; exit 1; }

BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
backup_if_conflict() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mkdir -p "$BACKUP"
    echo "  backup: $target -> $BACKUP/"
    mv "$target" "$BACKUP/"
  fi
}

echo "== stow dots from $DOTDIR =="
cd "$DOTDIR"

# Pre-backup known files that stow would clash with on a fresh Arch install
backup_if_conflict "$HOME/.bashrc"
backup_if_conflict "$HOME/.zshrc"
backup_if_conflict "$HOME/.zprofile"
backup_if_conflict "$HOME/.tmux.conf"
for d in hypr ghostty themes btop nvim quickshell scripts yazi zathura gtk qt6ct thunar; do
  if [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]]; then
    backup_if_conflict "$HOME/.config/$d"
  fi
done

for pkg in "${PACKAGES[@]}"; do
  echo "  stow: $pkg"
  stow -v -R --target="$HOME" "$pkg" 2>&1 | tail -n +1
done

# themes/current must be a direct symlink (not a stowed symlink-of-symlink)
rm -f "$HOME/.config/themes/current"
if [[ -d "$HOME/.config/themes/$THEME" ]]; then
  ln -s "$HOME/.config/themes/$THEME" "$HOME/.config/themes/current"
  echo "  theme: $THEME"
else
  echo "  error: linked theme '$THEME' is missing" >&2
  exit 2
fi

# btop expects themes/current.theme -> themes/current/btop.theme
mkdir -p "$HOME/.config/btop/themes"
rm -f "$HOME/.config/btop/themes/current.theme"
if [[ -f "$HOME/.config/themes/current/btop.theme" ]]; then
  ln -s "$HOME/.config/themes/current/btop.theme" "$HOME/.config/btop/themes/current.theme"
  echo "  btop theme linked"
fi

# shell scripts executable
chmod +x "$HOME/.config/scripts"/themes/set-theme.sh \
         "$HOME/.config/scripts"/wallpaper/hyprpaper.sh \
         "$HOME/.config/scripts"/layout/*.sh \
         "$HOME/.config/scripts"/remind/*.sh \
         "$HOME/.config/scripts"/windows/*.sh \
         "$HOME/.config/scripts"/utility/*.sh \
         "$HOME/.config/scripts"/presets/*.sh \
         "$HOME/.config/scripts"/todo/*.sh \
         "$HOME/.config/scripts"/utility/tmux/*.sh 2>/dev/null || true

# dirs the configs expect
mkdir -p "$HOME/Pictures/Screenshots" "$HOME/.cache"

# tmux plugin manager (plugins install on first tmux start via tpm)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "  tpm: cloning..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>&1 | tail -n1 || true
fi

echo ""
echo "done. Reload with: hyprctl reload; restart Quickshell if its config changed."
