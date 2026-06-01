#!/usr/bin/env bash
# target.sh — [ENGINE] target/ disk-usage chip.
#
# Reads $ENGINE_REPO/target size via du with a 30s on-disk cache so polling
# Waybar doesn't re-walk the build artifact tree every interval tick.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "engine" ]] || { echo ""; exit 0; }

REPO="${ENGINE_REPO:-$HOME/Projects/engine}"
TARGET="$REPO/target"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/engine-target-size"
TTL=30

# Refresh cache if missing or older than TTL.
if [[ ! -f "$CACHE" ]] || (( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) > TTL )); then
    if [[ -d "$TARGET" ]]; then
        du -sh "$TARGET" 2>/dev/null | awk '{print $1}' > "$CACHE" || echo "?" > "$CACHE"
    else
        printf -- "-\n" > "$CACHE"
    fi
fi

size=$(<"$CACHE")
if [[ "$size" == "-" ]]; then
    printf '{"text":"󰏗 · no build","class":"empty","tooltip":"%s/target does not exist"}\n' "$REPO"
else
    printf '{"text":"󰏗 %s","class":"ok","tooltip":"target/ disk usage (refreshed every %ss)"}\n' "$size" "$TTL"
fi
