# Hyprland on tty1 only when no display manager owns the session
# (greetd+tuigreet is the default on this rice; this is a fallback for tty logins)
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  if command -v Hyprland >/dev/null 2>&1; then
    exec Hyprland
  elif command -v hyprland >/dev/null 2>&1; then
    exec hyprland
  fi
fi
