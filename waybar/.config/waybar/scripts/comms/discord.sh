#!/usr/bin/env bash
# discord.sh — Discord process + unread badge.
#
# Unread count source: Discord embeds it in the window title as a leading
# "(N)" prefix when there are unread mentions or DMs. We read titles via the
# niri IPC (windows) which is cheaper than poking leveldb / IndexedDB.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "comms" ]] || { echo ""; exit 0; }

if ! pgrep -x discord >/dev/null && ! pgrep -x Discord >/dev/null; then
    printf '{"text":"󰙯 · offline","class":"empty","tooltip":"Discord not running"}\n'
    exit 0
fi

# Find the highest "(N)" badge across all Discord windows (Discord shows the
# total unread on its windows; multiple windows reflect the same total).
title=$(
    niri msg --json windows 2>/dev/null \
        | jq -r '.[] | select((.app_id // "") | ascii_downcase | contains("discord")) | .title' \
        | head -1
)

if [[ -z "$title" ]]; then
    printf '{"text":"󰙯 ON","class":"ok","tooltip":"Discord running (no window title yet)"}\n'
    exit 0
fi

badge=""
if [[ "$title" =~ ^\(([0-9]+)\) ]]; then
    badge="${BASH_REMATCH[1]}"
fi

if [[ -n "$badge" ]]; then
    printf '{"text":"󰙯 %s","class":"alert","tooltip":"Discord: %s unread (%s)"}\n' "$badge" "$badge" "$title"
else
    printf '{"text":"󰙯 ON","class":"ok","tooltip":"Discord: %s"}\n' "$title"
fi
