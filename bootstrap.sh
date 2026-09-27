#!/bin/bash
# Installs this package set at the latest versions in the current Arch/AUR repos,
# then applies the configs in this repo.
#
# Usage:
#   ./bootstrap.sh
#   ./bootstrap.sh --theme hamza
#
# What it does:
#   1. sudo keepalive + full system update
#   2. installs paru (AUR helper) if missing
#   3. installs packages/pacman.txt (official) + microcode/drivers per hardware
#   4. installs packages/aur.txt via paru
#   5. links dots via ./restore.sh (stow)
#   6. optional shell/login-manager/docker changes and common user services
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="hamza"
INTERACTIVE=1
usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--theme NAME] [--non-interactive]

Installs the latest Arch/AUR package versions and applies this desktop setup.
Optional changes to the login manager, shell, and Docker remain opt-in.
EOF
}
while (($#)); do
  case "$1" in
    --theme)
      [[ -n "${2:-}" ]] || { usage >&2; exit 2; }
      THEME="$2"; shift 2 ;;
    --non-interactive) INTERACTIVE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m! \033[0m %s\n' "$*"; }
confirm() {
  local answer
  [[ "$INTERACTIVE" == 1 && -t 0 ]] || { warn "skipping optional change: $1"; return 1; }
  read -r -p "$1 [y/N] " answer
  [[ "$answer" == [yY]* ]]
}
die() { printf '\033[1;31m!! \033[0m %s\n' "$*"; exit 1; }

[[ -f "$DOTDIR/packages/pacman.txt" ]] || die "packages/pacman.txt missing"
[[ -f "$DOTDIR/restore.sh" ]] || die "restore.sh missing"
[[ -f /etc/arch-release ]] || die "run this on Arch Linux after creating your user account"
command -v pacman >/dev/null || die "pacman is not installed"
[[ -d "$DOTDIR/themes/.config/themes/$THEME" ]] || die "unknown theme: $THEME"

# Optional local identity settings. Treat .env as trusted shell input and keep it
# out of Git; .env.example contains only empty placeholders.
if [[ -f "$DOTDIR/.env" ]]; then
  # shellcheck disable=SC1090
  source "$DOTDIR/.env"
fi
[[ -z "${GIT_USER_NAME:-}" ]] || git config --global user.name "$GIT_USER_NAME"
[[ -z "${GIT_USER_EMAIL:-}" ]] || git config --global user.email "$GIT_USER_EMAIL"

# --- sudo ---
log "checking sudo..."
sudo -v || die "sudo failed — run from a user in wheel"
( while true; do sudo -n true; sleep 50; kill -0 $$ || exit; done ) 2>/dev/null &
SUDO_ALIVE=$!
trap 'kill "$SUDO_ALIVE" 2>/dev/null || true; [[ -z "${PARU_BUILD_DIR:-}" ]] || rm -rf -- "$PARU_BUILD_DIR"' EXIT

# --- hardware detect ---
CPU_VENDOR="$(lscpu 2>/dev/null | awk -F: '/Vendor ID/{print $2}' | tr -d ' ' || true)"
HAS_NVIDIA=0
grep -q '^0x10de$' /sys/bus/pci/devices/*/vendor 2>/dev/null && HAS_NVIDIA=1 || true
HAS_BATTERY=0
compgen -G '/sys/class/power_supply/BAT*' >/dev/null && HAS_BATTERY=1 || true
HAS_BT=0
[[ -d /sys/class/bluetooth ]] && compgen -G '/sys/class/bluetooth/hci*' >/dev/null && HAS_BT=1 || true

log "hardware: cpu=${CPU_VENDOR:-unknown} nvidia=${HAS_NVIDIA} battery=${HAS_BATTERY} bt=${HAS_BT}"

# --- update ---
log "updating system (pacman -Syu)..."
sudo pacman -Syu --noconfirm

# --- base tools needed to build paru ---
sudo pacman -S --needed --noconfirm base-devel git

# --- paru (build latest upstream commit against this system's libalpm) ---
if ! paru --version >/dev/null 2>&1; then
  log "installing or repairing paru from latest paru-git..."
  OLD_PARU=()
  for package in paru paru-bin paru-git; do
    pacman -Q "$package" >/dev/null 2>&1 && OLD_PARU+=("$package") || true
  done
  if ((${#OLD_PARU[@]})); then
    sudo pacman -R --noconfirm "${OLD_PARU[@]}"
  fi
  PARU_BUILD_DIR="$(mktemp -d /tmp/paru-git.XXXXXX)"
  git clone --depth=1 https://aur.archlinux.org/paru-git.git "$PARU_BUILD_DIR"
  (cd "$PARU_BUILD_DIR" && makepkg -si --noconfirm)
  paru --version >/dev/null 2>&1 || die "paru build did not run; check the build output"
else
  log "paru is working"
fi

# --- official packages ---
log "installing official packages..."
mapfile -t PKGS < <(grep -v '^\s*#' "$DOTDIR/packages/pacman.txt" | grep -v '^\s*$' | awk '{print $1}')
# microcode per CPU (keeps images lean + correct on any machine)
if [[ "$CPU_VENDOR" == *GenuineIntel* ]]; then PKGS+=(intel-ucode); fi
if [[ "$CPU_VENDOR" == *AuthenticAMD* ]]; then PKGS+=(amd-ucode); fi
# nvidia only when present (intel-only laptops stay lean)
if [[ "$HAS_NVIDIA" == "1" ]]; then PKGS+=(nvidia nvidia-utils libva-nvidia-driver); fi
# drop candidates that conflict with what's already installed
# (e.g. pipewire-jack vs jack2 — jack2 wins, we keep the installed one)
FILTERED=()
for p in "${PKGS[@]}"; do
  if pacman -Q "$p" >/dev/null 2>&1; then FILTERED+=("$p"); continue; fi
  conflicts="$(pacman -Si "$p" 2>/dev/null | awk -F: '/^Conflicts With/{print $2}')"
  skip=""
  # shellcheck disable=SC2086
  for c in $conflicts; do
    if [[ "$c" != "None" ]] && pacman -Q "$c" >/dev/null 2>&1; then skip="$c"; break; fi
  done
  if [[ -n "$skip" ]]; then
    warn "skipping $p (conflicts with installed $skip — keeping $skip)"
  else
    FILTERED+=("$p")
  fi
done
sudo pacman -S --needed --noconfirm "${FILTERED[@]}"

# --- AUR packages ---
if [[ -f "$DOTDIR/packages/aur.txt" ]]; then
  mapfile -t AUPS < <(grep -v '^\s*#' "$DOTDIR/packages/aur.txt" | grep -v '^\s*$' | awk '{print $1}')
  if ((${#AUPS[@]})); then
    log "updating AUR packages and installing: ${AUPS[*]}"
    paru -Syu --needed --noconfirm "${AUPS[@]}" || die "AUR install/update failed; fix the reported package issue and rerun bootstrap"
  fi
fi

# polkit agent ships as a user service + /usr/lib binary (not $PATH)
systemctl --user enable hyprpolkitagent.service 2>/dev/null || true

# --- dots ---
log "linking dots (restore.sh)..."
chmod +x "$DOTDIR/restore.sh"
"$DOTDIR/restore.sh" --theme "$THEME"

# --- shell ---
if [[ "$SHELL" != *zsh ]] && confirm "Set zsh as your login shell?"; then
  log "setting zsh as default shell..."
  sudo chsh -s /bin/zsh "$USER" || warn "chsh failed — run 'chsh -s /bin/zsh' manually"
fi

# --- optional greetd login manager ---
if confirm "Configure greetd as the system login manager? This replaces the active display manager."; then
  log "configuring greetd..."
  sudo pacman -S --needed --noconfirm greetd greetd-tuigreet
  for dm in sddm gdm lightdm ly; do
    if systemctl is-active --quiet "$dm.service"; then
      log "disabling active display manager: $dm"
      sudo systemctl disable --now "$dm.service" || warn "could not disable $dm"
    fi
  done
  sudo mkdir -p /etc/greetd
  sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "greeter"
EOF
  sudo systemctl enable greetd.service 2>/dev/null || warn "could not enable greetd"
else
  warn "keeping the current login manager; select Hyprland from it or start Hyprland manually"
fi

# --- services  ---
log "enabling services..."
sudo systemctl enable NetworkManager.service 2>/dev/null || true
sudo systemctl enable power-profiles-daemon.service 2>/dev/null || true
if [[ "$HAS_BT" == "1" ]]; then
  sudo systemctl enable bluetooth.service 2>/dev/null || true
fi
if command -v docker >/dev/null; then
  if confirm "Enable Docker and add $USER to the docker group?"; then
    sudo systemctl enable docker.service 2>/dev/null || true
    sudo usermod -aG docker "$USER" 2>/dev/null || true
  fi
fi
# user services are socket-activated on Arch; ensure portals can start
systemctl --user daemon-reload 2>/dev/null || true

# --- quality-of-life ---
mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Documents" "$HOME/Downloads" "$HOME/Projects"
# first wallpaper immediately (SUPER+P cycles afterwards)
if command -v hyprctl >/dev/null && pgrep -x Hyprland >/dev/null; then
  "$HOME/.config/scripts/wallpaper/hyprpaper.sh" 2>/dev/null || true
fi

log "verifying quickshell..."
if command -v quickshell >/dev/null; then
  quickshell --version 2>&1 | head -n1 || true
  quickshell list 2>&1 | head -n8 || warn "quickshell isn't running — log out/in or run: quickshell -d -p ~/.config/quickshell"
else
  warn "quickshell binary missing — install failed?"
fi

echo ""
echo "==================================================="
echo " done. Log out and select Hyprland in your login manager."
echo ""
echo " keys:"
echo "   SUPER+SPACE   launcher (quickshell, replaces rofi)"
echo "   SUPER+V       clipboard picker"
echo "   SUPER+P       next wallpaper"
echo "   SUPER+SHIFT+E power menu"
echo "   SUPER+N       dismiss notifications"
echo "   SUPER+S       notes dropdown"
echo "   SUPER+CTRL+K  searchable keybindings"
echo "   SUPER+CTRL+T/W theme/wallpaper pickers"
echo "   theme: ~/.config/scripts/themes/set-theme.sh <name>"
echo ""
echo " reproduce anywhere:"
echo "   git clone <this-repo> ~/dots && ~/dots/bootstrap.sh"
echo " re-apply dots only:"
echo "   ~/dots/restore.sh"
echo "==================================================="
