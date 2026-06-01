#!/usr/bin/env bash
# zoom.sh — Zoom in-call indicator.
#
# Zoom doesn't expose a clean DBus state, but during a call its window names
# include "Zoom Meeting" or "Webinar". When idle, only the main Zoom client
# process runs but no meeting windows exist. We use niri IPC to detect
# meeting windows.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "comms" ]] || { echo ""; exit 0; }

# Is the zoom client even running?
if ! pgrep -ix zoom >/dev/null 2>&1; then
    printf '{"text":"󰍫 · offline","class":"empty","tooltip":"Zoom not running"}\n'
    exit 0
fi

# Check for active meeting windows
meeting_title=$(
    niri msg --json windows 2>/dev/null \
        | jq -r '.[] | select((.app_id // "") | ascii_downcase | contains("zoom")) | .title' \
        | grep -iE '(Meeting|Webinar|Zoom Workplace.*Meeting)' \
        | head -1
)

if [[ -n "$meeting_title" ]]; then
    printf '{"text":"󰍫 LIVE","class":"alert","tooltip":"Zoom in call: %s"}\n' "$meeting_title"
else
    printf '{"text":"󰍫 idle","class":"ok","tooltip":"Zoom client running, no active meeting"}\n'
fi
