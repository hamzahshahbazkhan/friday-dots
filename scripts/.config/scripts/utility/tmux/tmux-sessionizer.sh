#!/usr/bin/env bash
set -euo pipefail

search_dirs=("$HOME/Projects" "$HOME/Friday" "$HOME/dots" "$HOME/.config")
existing=()
for dir in "${search_dirs[@]}"; do
  [[ -d "$dir" ]] && existing+=("$dir")
done

if [[ -n "${1:-}" ]]; then
  selected=$(realpath -e -- "$1")
else
  ((${#existing[@]})) || { echo 'No sessionizer search directories exist.' >&2; exit 1; }
  selected=$(find "${existing[@]}" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort -u | fzf --prompt='Project › ' --height=40% --reverse) || exit 0
fi
[[ -d "$selected" ]] || { echo "Not a directory: $selected" >&2; exit 2; }

name=$(basename "$selected" | tr -cs '[:alnum:]_-' '_')
if ! tmux has-session -t="$name" 2>/dev/null; then
  tmux new-session -ds "$name" -c "$selected"
fi

if [[ -n "${TMUX:-}" ]]; then
  exec tmux switch-client -t "$name"
fi
exec tmux attach-session -t "$name"
