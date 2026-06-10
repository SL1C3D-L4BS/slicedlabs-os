#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# top-mem.sh — process consuming the most resident memory right now.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "monitoring" ]] || { echo ""; exit 0; }

read -r name kb < <(ps -eo comm,rss --sort=-rss --no-headers 2>/dev/null | awk 'NR==1{print $1, $2}')
name="${name:-?}"
kb="${kb:-0}"

# Render in human units (KB → MB → GB).
if (( kb >= 1048576 )); then
    human=$(printf '%.1fG' "$(awk "BEGIN{print $kb/1048576}")")
elif (( kb >= 1024 )); then
    human=$(printf '%dM' "$(( kb / 1024 ))")
else
    human="${kb}K"
fi

# Total memory in KB, for percent calc.
total=$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo)
pct=$(( total > 0 ? (kb * 100) / total : 0 ))

cls="ok"
(( pct >= 25 )) && cls="alert"
(( pct >= 50 )) && cls="critical"

printf '{"text":"󰍛 %s %s","class":"%s","tooltip":"Top RSS consumer · %d%% of system memory"}\n' "$name" "$human" "$cls" "$pct"
