#!/usr/bin/env bash
# agents.sh — active agent count (AI HUD).
# Source order: ~/.cache/slicedlabs/agents.count -> `slicedlabs agents --count`
# -> pgrep claude (fallback). Degrades gracefully.
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "ai" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

n=""
if command -v slicedlabs >/dev/null 2>&1; then
    n=$(slicedlabs agents --format json 2>/dev/null | jq -r '.active // empty' 2>/dev/null)
fi
[[ -z "$n" ]] && n=$(pgrep -fc 'claude' 2>/dev/null || echo 0)

cls="ok"; (( n > 0 )) && cls="info"
emit "$G_AI ${n} agents" "$cls" "active agents: $n · click: slicedlabs agents"
