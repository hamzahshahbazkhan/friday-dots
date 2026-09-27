#!/bin/bash
# `remind` CLI — thin wrapper over reminders.sh (same backend as the widget).
#   remind 7 'Tea ready'   schedule
#   remind view            list pending
#   remind clear           cancel all
set -u
HELPER="$HOME/.config/scripts/remind/reminders.sh"

case "${1:-}" in
  view)
    out="$("$HELPER" list)"
    if [[ -z "$out" ]]; then
      notify-send "Reminders" "none pending" -t 2500
    else
      body="$(awk -F'|' '{printf "• %s\n", $3}' <<<"$out")"
      notify-send "Reminders" " $body" -t 8000
    fi
    ;;
  clear)
    "$HELPER" clear
    notify-send "Reminders" "cleared" -t 2500
    ;;
  ""|help|-h|--help)
    echo "usage: remind <minutes> <message> | remind view | remind clear" >&2
    ;;
  *)
    if [[ $# -ge 2 && "$1" =~ ^[0-9]+$ ]]; then
      mins="$1"; shift; msg="$*"
      if id="$("$HELPER" schedule "$mins" "$msg")"; then
        notify-send "Reminder set" "$msg — in ${mins}m" -t 2500
      else
        notify-send "Reminder" "could not schedule" -t 3000
      fi
    else
      ghostty -e bash -lc 'read -rp "minutes: " m && read -rp "message: " t && remind "$m" "$t"; sleep 1' &
    fi
    ;;
esac
