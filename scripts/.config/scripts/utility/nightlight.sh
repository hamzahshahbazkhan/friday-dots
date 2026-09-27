#!/usr/bin/env bash
set -euo pipefail

action=${1:-off}
temperature=${2:-3500}
[[ "$action" == on || "$action" == off ]] || { echo 'usage: nightlight.sh on|off [temperature]' >&2; exit 2; }
[[ "$temperature" =~ ^[0-9]+$ ]] && (( temperature >= 1000 && temperature <= 6500 )) || { echo 'temperature must be 1000–6500 K' >&2; exit 2; }
command -v hyprsunset >/dev/null || { echo 'hyprsunset is not installed' >&2; exit 127; }

mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
pkill -u "$(id -u)" -x hyprsunset 2>/dev/null || true
sleep 0.15
if [[ "$action" == on ]]; then
  nohup hyprsunset --temperature "$temperature" >"${XDG_CACHE_HOME:-$HOME/.cache}/hyprsunset.log" 2>&1 </dev/null &
else
  nohup hyprsunset --identity >"${XDG_CACHE_HOME:-$HOME/.cache}/hyprsunset.log" 2>&1 </dev/null &
fi
