#!/usr/bin/env bash
# top-cpu.sh — process consuming the most CPU right now.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "monitoring" ]] || { echo ""; exit 0; }

read -r name pct < <(ps -eo comm,pcpu --sort=-pcpu --no-headers 2>/dev/null | awk 'NR==1{print $1, $2}')
name="${name:-?}"
pct="${pct:-0.0}"
pct_int="${pct%.*}"

cls="ok"
(( pct_int >= 80 )) && cls="alert"
(( pct_int >= 95 )) && cls="critical"

printf '{"text":"󰓅 %s %s%%","class":"%s","tooltip":"Top CPU consumer right now"}\n' "$name" "$pct" "$cls"
