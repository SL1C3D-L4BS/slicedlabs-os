#!/usr/bin/env bash
# pomo.sh — coding tab Pomodoro countdown chip. Wraps `uairctl fetch`.

set -eu

tab_id="coding"
active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

if ! command -v uairctl >/dev/null 2>&1; then
  printf '{"text":"no uair","class":"info","tooltip":"install layer J"}\n'
  exit 0
fi

# uairctl fetch — pause-aware. Returns "<name> <time>" or empty on idle.
raw=$(uairctl fetch '{name} {time}' 2>/dev/null || true)
if [[ -z "$raw" ]]; then
  printf '{"text":" idle","class":"paused","tooltip":"uairctl resume to start"}\n'
  exit 0
fi

# Crude state classifier — when time is "00:00" treat as transition.
name=$(awk '{print $1}' <<<"$raw")
time=$(awk '{print $2}' <<<"$raw")

class="work"
case "$name" in
  Break|Long*|Recovery) class="break" ;;
esac

printf '{"text":" %s %s","class":"%s","tooltip":"session: %s\\nclick: pause/resume"}\n' \
  "$name" "$time" "$class" "$name"
