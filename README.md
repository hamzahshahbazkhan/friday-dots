# Friday's Arch desktop

Arch Linux + Hyprland dotfiles, with Quickshell providing the bar,
launcher, quick controls, notifications, and OSD. `bootstrap.sh` installs the
package set and offers optional system changes; `restore.sh` reapplies the
user configuration without reinstalling packages.

## Install after Arch

```bash
git clone https://github.com/hamzahshahbazkhan/dots.git ~/dots
cd ~/dots
cp .env.example .env       # optional: set your local Git name and email
./bootstrap.sh             # choose the greetd, shell, and Docker prompts
```

Select **Hyprland** in your login manager after logging out. To only relink the
dotfiles or change the initial theme:

```bash
~/dots/restore.sh
~/dots/restore.sh --theme gruvbox
```

For a non-interactive run, use
`./bootstrap.sh --theme hamza --non-interactive`. This skips optional system
changes; it does not replace your display manager or enable Docker. See the
[visual setup guide](docs/guide.html) for installation, updates,
troubleshooting, and theme maintenance.

The scripts target an already installed Arch Linux system. They do not
partition disks or pin the Arch rolling repositories to a package snapshot.
Hardware-specific microcode, NVIDIA drivers, and Bluetooth service setup are
detected where applicable. Package lists are in `packages/`.

## Desktop controls

- `Super+Space`: app launcher; search **keybindings**, **theme**, or **wallpaper** for the matching picker.
- `Super+Ctrl+K`: searchable shortcut reference; `Super+Ctrl+T`: color-theme picker; `Super+Ctrl+W`: wallpaper thumbnail picker.
- `Super+V`: clipboard; `Super+.`: emoji picker; `Super+P`: next wallpaper.
- `Super+S`: toggle the dedicated drop-down notes window editing `~/Friday/buffer.md`.
- `Super+Shift+E`: power menu; `Super+N`: dismiss notifications; `Alt+Ctrl+L`: lock.
- `Super+arrows` or `Super+h/j/k/l`: focus; add Shift to move a window. `Super+Shift+L` switches layout.
- Click the centered clock for the calendar; right-click it to toggle the date format. Wi-Fi and Bluetooth open their device panels; CPU/RAM open btop; battery opens power profiles. Hover Wi-Fi to see the connected network and IP. Nightlight and power menu sit hidden just left of the clock until hovered.
- `Super+Ctrl+F` opens the tmux project sessionizer (inside tmux, `prefix+f`).
- `theme <name>` switches the theme. Quickshell and Hyprland reload; reopen Ghostty, Neovim, Zathura, and GTK app sessions to apply their new colors.

Panels use `j`/`k`, arrow keys, Enter, and Escape where selection applies. Battery warnings appear at 20% and 10%. Notifications expire automatically.

## Themes, wallpapers, and local settings

Theme creation and required files are documented in [docs/themes.md](docs/themes.md). Run `./scripts/check-themes.sh` to validate them. Add wallpapers to `wallpapers/.config/.wallpapers`; change the lock image path in `hypr/.config/hypr/hyprlock.conf`.

`.env` is ignored by Git. It supports optional `GIT_USER_NAME` and
`GIT_USER_EMAIL` values; `.env.example` contains placeholders only. Do not store
passwords, tokens, or private keys in this repository. Restore app credentials
from a local password manager or sign in again on each machine. GitHub access
should use your SSH key or Git's credential helper, kept outside this repo.

## Included

Hyprland Lua config, Hyprlock/Hypridle, Quickshell widgets, Ghostty, Neovim,
Zsh, tmux, Yazi, Thunar, Zathura, GTK/Qt settings, themes, wallpapers, and
utility scripts. The package manifest also installs Telegram Desktop.

## Checks

```bash
find . -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
./scripts/check-themes.sh
```

For setup details and troubleshooting, see [docs/setup.md](docs/setup.md).
