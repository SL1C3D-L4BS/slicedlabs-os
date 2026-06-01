#!/usr/bin/env bash
# alerts.sh — always-visible urgency badge (left cluster). Renders the glyphs of
# any tabs flagged urgent by waybard; collapses (empty) when nothing is urgent.
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

urgent=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-urgent" 2>/dev/null || echo "")
[[ -z "${urgent// /}" ]] && { echo ""; exit 0; }

declare -A GLY=(
    [engine]="$G_ENGINE" [comms]="$G_COMMS" [stream]="$G_STREAM"
    [monitoring]="$G_MONITORING" [gaming]="$G_GAMING" [coding]="$G_CODING"
    [browser]="$G_BROWSER" [media]="$G_MEDIA" [net]="$G_NET"
    [ai]="$G_AI" [agenda]="$G_AGENDA"
)
out=""
for t in $urgent; do out+="${GLY[$t]:-$G_BELL} "; done
out="${out% }"

jq -cn --arg t "$G_BELL $out" --arg tt "urgent: $urgent · click: dismiss" \
    '{text:$t, class:"urgent", tooltip:$tt}'
