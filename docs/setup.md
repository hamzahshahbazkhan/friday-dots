# Setup and maintenance

## Fresh machine

1. Install Arch Linux, create a normal user with `sudo` access, and make sure
   networking works.
2. Clone this repo to `~/dots`. Review `.env.example`, optionally copy it to
   `.env`, and fill only your Git display name/email.
3. Run `./bootstrap.sh`. It installs the package manifests, links configs, and
   enables NetworkManager and power profiles. It asks before changing the
   login manager, login shell, or Docker group. A non-interactive run skips
   those optional changes.
4. Log out, select Hyprland in your login manager, and sign in.

Run `./restore.sh` after updating dotfiles. It backs up conflicting config
directories before linking them and does not reinstall packages. Pass
`--theme <name>` to select a theme during relinking.

## Local credentials

The `.env` file is sourced by `bootstrap.sh` as shell input. Only use a file
you wrote and trust. It currently supports `GIT_USER_NAME` and
`GIT_USER_EMAIL`; it is not a credential store and no passwords or tokens are
read from it. Use SSH or Git's credential helper for GitHub authentication.
App accounts and browser profiles are intentionally local to each device.

## Packages and services

Edit `packages/pacman.txt` and `packages/aur.txt` to change the installed app
set. Hardware checks add CPU microcode and NVIDIA drivers where detected.
Bluetooth service setup is conditional. The setup script does not uninstall
legacy packages or replace an existing display manager unless you approve the
greetd prompt; greetd is installed only when selected. Docker is installed from
the package manifest, but its daemon and group membership remain opt-in.

Arch is rolling-release: package versions are not pinned. The scripts provide
the same package names and dotfiles on new machines, but not a byte-for-byte
snapshot of repository versions.

Use `./bootstrap.sh --theme <name> --non-interactive` to skip optional
questions. For the usual one-command setup on a new Arch install, run
`./bootstrap.sh --theme hamza` and answer only the optional questions you
want. CPU type is read with `lscpu`; NVIDIA cards, batteries, and Bluetooth
adapters are detected from sysfs. CPU microcode, NVIDIA drivers, and Bluetooth
service setup are added only when detected. Zsh plugins come from the current
Arch repositories and no longer download during shell startup.

Neovim plugin commits are not pinned either. A fresh install follows each
plugin's default branch; run `:Lazy sync` in Neovim to update an existing
install.

## Updating and troubleshooting

- Update the repo, then run `./restore.sh` to relink changed settings.
- Restart Quickshell with `quickshell kill && quickshell --daemonize` if its
  widgets fail to load. Check `quickshell log` for QML errors.
- Run `hyprctl reload` after compositor changes; current Hyprland uses
  `hypr/.config/hypr/hyprland.lua`.
- Check that `NetworkManager`, `power-profiles-daemon`, and `bluetooth` are
  running when using their quick controls.
- Run `./scripts/check-themes.sh` after editing a theme.
- `Super+Ctrl+K` opens the shortcut guide; `Super+Ctrl+T` and `Super+Ctrl+W`
  open separate theme and wallpaper pickers. `Super+S` toggles the notes
  scratchpad at `~/Friday/buffer.md`.
