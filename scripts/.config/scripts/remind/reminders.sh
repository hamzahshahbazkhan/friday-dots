#!/bin/bash
# Reminder backend shared by the quickshell widget and the `remind` CLI.
#   reminders.sh schedule <minutes> <message>  — prints id, fires via quickshell
#   reminders.sh list                          — prints id|epoch|message lines
#   reminders.sh clear                         — cancel everything
#   reminders.sh msg <id>                      — print one message
set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/reminders"
mkdir -p "$STATE_DIR"

case "${1:-}" in
  schedule)
    mins="${2:-}"; shift 2 2>/dev/null || true; msg="$*"
    [[ "$mins" =~ ^[0-9]+$ ]] || { echo "minutes must be a number" >&2; exit 1; }
    [[ -z "$msg" ]] && { echo "message is empty" >&2; exit 1; }
    id="$(date +%s)-$RANDOM"
    fire_at=$(( $(date +%s) + mins * 60 ))
    printf '%s\n%s\n' "$fire_at" "$msg" > "$STATE_DIR/$id"
    systemd-run --user --on-active="${mins}min" --timer-property=AccuracySec=1s --unit="reminder-$id" \
      quickshell ipc call reminder fire "$id" &>/dev/null \
      || { echo "could not schedule" >&2; exit 1; }
    echo "$id"
    ;;
  list)
    for f in "$STATE_DIR"/*; do
      [[ -f "$f" ]] || continue
      id="$(basename "$f")"
      epoch="$(sed -n '1p' "$f")"
      msg="$(sed -n '2,$p' "$f" | tr '\n' ' ')"
      printf '%s|%s|%s\n' "$id" "$epoch" "$msg"
    done
    ;;
  clear)
    for u in $(systemctl --user list-units 'reminder-*' --no-legend --no-pager 2>/dev/null | awk '{print $1}'); do
      systemctl --user stop "$u" 2>/dev/null || true
    done
    rm -f "$STATE_DIR"/*
    ;;
  msg)
    sed -n '2,$p' "$STATE_DIR/${2:-}" 2>/dev/null | tr '\n' ' '
    ;;
  *)
    echo "usage: reminders.sh {schedule <min> <msg>|list|clear|msg <id>}" >&2; exit 1
    ;;
esac
