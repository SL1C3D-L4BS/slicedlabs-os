#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# notifs.sh — unacknowledged desktop notifications via mako.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "comms" ]] || { echo ""; exit 0; }

if ! command -v makoctl >/dev/null; then
    printf '{"text":"󰂚 · n/a","class":"empty","tooltip":"makoctl not installed"}\n'
    exit 0
fi

if ! pgrep -x mako >/dev/null; then
    printf '{"text":"󰂚 · off","class":"empty","tooltip":"mako daemon not running"}\n'
    exit 0
fi

# `makoctl list` returns JSON: { data: [[ {...}, {...} ]] }
count=$(makoctl list 2>/dev/null | jq '[.data[0][]] | length' 2>/dev/null || echo 0)
count="${count:-0}"

if (( count > 0 )); then
    printf '{"text":"󰂚 %d","class":"alert","tooltip":"%d waiting notification(s) — makoctl dismiss"}\n' "$count" "$count"
else
    printf '{"text":"󰂜 0","class":"ok","tooltip":"Inbox zero (mako)"}\n'
fi
