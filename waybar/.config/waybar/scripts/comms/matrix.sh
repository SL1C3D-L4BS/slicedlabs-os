#!/usr/bin/env bash
# matrix.sh — Element Desktop (Matrix) unread badge.
#
# Element shows total unread mentions/messages as a leading "(N)" prefix on the
# main window title — same convention as Discord. We read the title via niri
# IPC; falls back to "running" if no badge is parseable.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "comms" ]] || { echo ""; exit 0; }

if ! pgrep -fx '.*[Ee]lement.*' >/dev/null 2>&1; then
    printf '{"text":"󰵄 · offline","class":"empty","tooltip":"Element/Matrix not running"}\n'
    exit 0
fi

title=$(
    niri msg --json windows 2>/dev/null \
        | jq -r '.[] | select((.app_id // "") | ascii_downcase | contains("element")) | .title' \
        | head -1
)

if [[ -z "$title" ]]; then
    printf '{"text":"󰵄 ON","class":"ok","tooltip":"Element/Matrix running (no window title yet)"}\n'
    exit 0
fi

badge=""
if [[ "$title" =~ ^\(([0-9]+)\) ]]; then
    badge="${BASH_REMATCH[1]}"
fi

if [[ -n "$badge" ]]; then
    printf '{"text":"󰵄 %s","class":"alert","tooltip":"Element/Matrix: %s unread (%s)"}\n' "$badge" "$badge" "$title"
else
    printf '{"text":"󰵄 ON","class":"ok","tooltip":"Element/Matrix: %s"}\n' "$title"
fi
