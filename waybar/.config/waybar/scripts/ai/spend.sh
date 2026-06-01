#!/usr/bin/env bash
# spend.sh — Claude/agent token spend vs cost-cap (AI HUD).
# Source order: ~/.cache/slicedlabs/spend.json -> `slicedlabs cost --json`.
# Expected JSON: {"today_usd":N,"cap_usd":M}. Degrades to empty if unavailable.
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "ai" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

# Same source/contract the coding-team chip uses: `slicedlabs cost today` JSON
# with .total (USD today), .soft_cap (daily soft cap), .active (agent count).
if ! command -v slicedlabs >/dev/null 2>&1; then
    emit "$G_SPEND n/a" empty "slicedlabs CLI not on PATH"; exit 0
fi
json=$(slicedlabs cost today --format=json 2>/dev/null || echo "{}")
today=$(jq -r '.total // empty' <<<"$json" 2>/dev/null)
cap=$(jq -r '.soft_cap // empty' <<<"$json" 2>/dev/null)
[[ -z "$today" ]] && { emit "$G_SPEND \$0.00" ok "no spend recorded today · click: slicedlabs cost"; exit 0; }
today=$(awk "BEGIN{printf \"%.2f\", ${today:-0}}")

cls="ok"
if [[ -n "$cap" && "$cap" != "0" && "$cap" != "null" ]]; then
    pct=$(awk "BEGIN{printf \"%d\", ($today/$cap)*100}")
    (( pct >= 70 )) && cls="alert"
    (( pct >= 100 )) && cls="critical"
    emit "$G_SPEND \$$today/$cap" "$cls" "today: \$$today / \$$cap cap (${pct}%) · click: slicedlabs cost"
else
    emit "$G_SPEND \$$today" "$cls" "today: \$$today · click: slicedlabs cost"
fi
