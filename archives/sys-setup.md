# SYSTEM_SETUP.md

**No longer relevant**

Documentation of my Arch Linux + Hyprland setup
Terminal commands, system monitoring, tweaking, and tools
Only includes installed packages

## 1️⃣ System Overview

- **OS:** Arch Linux (Kernel 6.16 + Linux-LTS 6.12 available)
- **Desktop Environment / WM:** Hyprland (Wayland)
- **Lock Screen:** hyprlock
- **Notifications:** mako
- **Terminal:** ghostty, alacritty, kitty, astroterm
- **Shell:** zsh (default via `chsh -s /usr/bin/zsh`)
- **Clipboard Manager:** cliphist, wl-clipboard
- **Package Manager:** pacman + paru / yay AUR helper

## 2️⃣ CPU & Memory Monitoring

| Tool      | Command     | Description                                                  |
| --------- | ----------- | ------------------------------------------------------------ |
| btop      | `btop`      | Fancy interactive CPU, memory, disk, network monitor         |
| fastfetch | `fastfetch` | System overview summary: CPU, GPU, kernel, OS, uptime        |
| htop      | `htop`      | Interactive process viewer (if installed)                    |
| neofetch  | `neofetch`  | Another system summary (CPU, memory, GPU, OS, shell, uptime) |
| free      | `free -h`   | Shows memory usage in human-readable format                  |
| vmstat    | `vmstat 1`  | Real-time view of memory, CPU, I/O stats                     |
| top       | `top`       | Default process and CPU usage monitor                        |

## 3️⃣ GPU Monitoring & Tweaking

| Tool            | Command                  | Description                                                   |
| --------------- | ------------------------ | ------------------------------------------------------------- |
| nvidia-smi      | `nvidia-smi`             | NVIDIA GPU stats, usage, temperature (requires NVIDIA driver) |
| nvidia-settings | `nvidia-settings`        | GUI for configuring NVIDIA GPU (fan, power, display)          |
| glxinfo         | `glxinfo \| grep OpenGL` | Shows OpenGL renderer, GPU used for 3D acceleration           |
| prime-run       | `prime-run <app>`        | Runs app on NVIDIA GPU (Optimus laptops)                      |
| vulkaninfo      | `vulkaninfo`             | Vulkan-capable GPU info (if Vulkan SDK installed)             |

## 4️⃣ Audio Management

| Tool        | Command                       | Description                                       |
| ----------- | ----------------------------- | ------------------------------------------------- |
| pamixer     | `pamixer --get-volume`        | Command-line volume control (PulseAudio/PipeWire) |
| pulsemixer  | `pulsemixer`                  | Terminal-based mixer UI for PulseAudio/PipeWire   |
| pavucontrol | `pavucontrol`                 | GUI for PulseAudio/PipeWire devices and volumes   |
| wpctl       | `wpctl set-volume <sink> 5%+` | PipeWire volume adjustments                       |

## 5️⃣ File & Disk Utilities

| Tool    | Command            | Description                                 |
| ------- | ------------------ | ------------------------------------------- |
| fd      | `fd <pattern>`     | Simple, fast alternative to `find`          |
| ripgrep | `rg <pattern>`     | Fast search through files                   |
| bat     | `bat <file>`       | `cat` clone with syntax highlighting        |
| exa     | `exa`              | Modern replacement for `ls`                 |
| zoxide  | `zoxide add <dir>` | Smart directory jumping (cd alternative)    |
| rsync   | `rsync -av`        | Sync/copy files between folders or machines |

## 6️⃣ PDF & Document Tools

| Tool              | Command                 | Description                                           |
| ----------------- | ----------------------- | ----------------------------------------------------- |
| zathura           | `zathura <file.pdf>`    | Lightweight PDF viewer, customizable via `.zathurarc` |
| zathura-pdf-mupdf | `zathura -p <file.pdf>` | MuPDF backend for faster PDF rendering                |
| libreoffice-still | `libreoffice`           | Full-featured office suite                            |

## 7️⃣ Media & Image Tools

| Tool  | Command       | Description                                       |
| ----- | ------------- | ------------------------------------------------- |
| vlc   | `vlc <file>`  | Media player supporting almost all formats        |
| mpv   | `mpv <file>`  | Lightweight media player for terminal or GUI      |
| imv   | `imv <image>` | Lightweight image viewer with keyboard navigation |
| loupe |
| gimp  | `gimp <file>` | Advanced image editor                             |

## 8️⃣ Networking & Bluetooth

| Tool                   | Command        | Description                              |
| ---------------------- | -------------- | ---------------------------------------- |
| networkmanager         | `nmcli`        | CLI for NetworkManager management        |
| network-manager-applet | `nm-applet`    | GUI for managing networks in system tray |
| bluez / bluetoothctl   | `bluetoothctl` | CLI for Bluetooth devices                |
| blueman                | `blueman`      | GUI for Bluetooth devices management     |
| blueberry              | `blueberry`    | GUI for Bluetooth on desktops            |

## 9️⃣ Power Management

| Tool     | Command                                                  | Description                             |
| -------- | -------------------------------------------------------- | --------------------------------------- |
| tlp      | `sudo tlp start`                                         | Advanced power management for laptops   |
| powertop | `sudo powertop`                                          | Power usage monitoring and optimization |
| upower   | `upower -i /org/freedesktop/UPower/devices/battery_BAT0` | Battery info and stats                  |

## 🔟 ASUS Laptop Control

| Tool    | Command                | Description                                     |
| ------- | ---------------------- | ----------------------------------------------- |
| asusctl | `asusctl --help`       | ASUS laptop control for backlight, profiles etc |
| asusctl | `asusctl profile -l`   | List available performance profiles             |
| asusctl | `asusctl led`          | Control keyboard LED lighting                   |
| asusctl | `asusctl fan-curve -i` | View/modify fan curves                          |

**Note:** OpenRGB didn't work. Had to skip the GUI component during makepkg by updating PKGBUILD due to memory constraints during compilation.

## 🔧 Additional Utilities

| Tool      | Command                              | Description                                                |
| --------- | ------------------------------------ | ---------------------------------------------------------- |
| rofi      | `rofi -show drun`                    | Application launcher, window switcher, run dialog          |
| fzf       | `fzf`                                | Interactive fuzzy finder in terminal                       |
| glow      | `glow <file.md>`                     | Terminal Markdown renderer                                 |
| timeshift | `sudo timeshift`                     | System backup & restore utility                            |
| stow      | `stow <package>`                     | Manage dotfiles and configuration folders                  |
| wget      | `wget <url>`                         | CLI downloader                                             |
| git       | `git`                                | Version control system                                     |
| hyprctl   | `hyprctl <command>`                  | Control Hyprland from terminal (workspaces, windows, etc.) |
| hyprshot  | `hyprshot -m <window/output/region>` | Screenshots in Hyprland                                    |
| swww      | `swww <image>`                       | Set wallpapers in Hyprland                                 |
| walker    | `walker <file>`                      | Terminal image viewer                                      |

- battery alerts are now handled by Quickshell at 20% and 10%; no cron job is needed
- battery max limit set to 65 as it is plugged in most time

## 🔮 Recommended / Optional Tools

- alsamixer / alsa-utils (CLI mixer for ALSA)
- speedtest-cli (network testing)
- htop (process monitoring)
- neofetch (system overview)
- newsboat (terminal RSS reader)
- swappy / grim / slurp (screenshots)
- openrgb (RGB lighting control)
- wireshark (network packet analyzer)
- obs (streaming/recording)

---

_This document is maintained for Hamzah Shahbaz Khan's Arch Linux + Hyprland setup for reference, monitoring, and system tweaking._
