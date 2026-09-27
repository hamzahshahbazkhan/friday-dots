#!/usr/bin/env bash
# Cycles wallpapers in strict alphabetical (by filename), case-insensitive, natural order (…1,2,10…).
# Backend: awww (swww successor). Remembers position across runs. Applies to all monitors.
# SUPER+P is bound to this script.

set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/.wallpapers}"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper_index"
mkdir -p "$(dirname "$STATE_FILE")"

command -v awww >/dev/null || { echo "awww not installed (run ~/dots/bootstrap.sh)" >&2; exit 1; }
pgrep -x awww-daemon >/dev/null || { awww-daemon &>/dev/null & sleep 1; }

# 1) Collect files
mapfile -t FILES < <(
  find -L "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \)
)

(( ${#FILES[@]} > 0 )) || { echo "No images in $WALLPAPER_DIR" >&2; exit 1; }

# 2) Sort by BASENAME alphabetically (case-insensitive), with natural/“version” order for numbers
pairs=()
for f in "${FILES[@]}"; do
  pairs+=( "$(basename "$f")"$'\x1f'"$f" )
done

IFS=$'\n' read -r -d '' -a SORTED_PAIRS < <(
  printf '%s\n' "${pairs[@]}" \
  | LC_ALL=C sort -f -V && printf '\0'
)

WALLS=()
for rec in "${SORTED_PAIRS[@]}"; do
  WALLS+=( "${rec#*$'\x1f'}" )
done

COUNT=${#WALLS[@]}

# Apply a selected image (used by Quickshell's appearance picker).
if [[ "${1:-}" == "--set" ]]; then
  [[ -n "${2:-}" && -f "$2" ]] || { echo "usage: $0 --set <wallpaper-file>" >&2; exit 2; }
  TARGET="$(realpath -- "$2")"
  ROOT="$(realpath -- "$WALLPAPER_DIR")"
  [[ "$TARGET" == "$ROOT/"* ]] || { echo "wallpaper must be inside $WALLPAPER_DIR" >&2; exit 2; }
  FOUND=-1
  for i in "${!WALLS[@]}"; do
    if [[ "$(realpath -- "${WALLS[$i]}")" == "$TARGET" ]]; then FOUND=$i; break; fi
  done
  (( FOUND >= 0 )) || { echo "wallpaper is not in the configured wallpaper list" >&2; exit 2; }
  printf '%s\n' "$FOUND" > "$STATE_FILE"
  awww img "$TARGET" --transition-type simple --transition-fps 90 --transition-step 8
  exit
fi

# 3) Read last index (default -1), compute next (wrap to first after last)
IDX=-1
[[ -f "$STATE_FILE" ]] && read -r IDX < "$STATE_FILE" || true
[[ "$IDX" =~ ^[0-9]+$ ]] || IDX=-1
NEXT=$(( (IDX + 1) % COUNT ))
printf '%s\n' "$NEXT" > "$STATE_FILE"

NEXT_WALL="${WALLS[$NEXT]}"

# 4) Apply to all monitors with a transition; first run paints instantly
if [[ "$IDX" == "-1" ]]; then
  awww img "$NEXT_WALL" --transition-type none
else
  awww img "$NEXT_WALL" --transition-type simple --transition-fps 144 --transition-step 8
fi
