#!/usr/bin/env bash
# disk-pressure.sh — root partition usage % (free space pressure).
#
# Tiers:
#   ok       : usage < 70%
#   alert    : 70% ≤ usage < 85%
#   critical : usage ≥ 85%
#
# Caches the result for 30s to avoid repeating df / stat work on every interval.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "monitoring" ]] || { echo ""; exit 0; }

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/disk-pressure"
TTL=30

if [[ ! -f "$CACHE" ]] || (( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) > TTL )); then
    used_pct=$(df --output=pcent / 2>/dev/null | tail -1 | tr -d ' %' || echo 0)
    avail=$(df --output=avail -h / 2>/dev/null | tail -1 | tr -d ' ' || echo "?")
    printf '%s %s\n' "$used_pct" "$avail" > "$CACHE"
fi

read -r used_pct avail < "$CACHE"

if (( used_pct >= 85 )); then
    cls="critical"; icon="󰋊"
elif (( used_pct >= 70 )); then
    cls="alert"; icon="󰋊"
else
    cls="ok"; icon="󰋊"
fi

printf '{"text":"%s %d%%","class":"%s","tooltip":"root partition: %d%% used (%s free) — refreshed every %ss"}\n' \
    "$icon" "$used_pct" "$cls" "$used_pct" "$avail" "$TTL"
