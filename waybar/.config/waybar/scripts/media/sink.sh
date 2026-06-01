#!/usr/bin/env bash
# sink.sh — default output sink + volume (media HUD).
#   (no args)  render the chip
#   --cycle    switch default sink to the next one (wired to on-click)
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

if [[ "${1:-}" == "--cycle" ]]; then
    mapfile -t sinks < <(pactl list short sinks 2>/dev/null | awk '{print $2}')
    cur=$(pactl get-default-sink 2>/dev/null || echo "")
    n=${#sinks[@]}; (( n == 0 )) && exit 0
    idx=0; for i in "${!sinks[@]}"; do [[ "${sinks[$i]}" == "$cur" ]] && idx=$i; done
    pactl set-default-sink "${sinks[$(( (idx + 1) % n ))]}" 2>/dev/null || true
    exit 0
fi

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "media" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

if ! command -v wpctl >/dev/null 2>&1; then emit "$G_SPEAKER n/a" empty "wpctl not installed"; exit 0; fi

raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "")
vol=$(awk '{print int($2*100)}' <<<"$raw" 2>/dev/null)
vol=${vol:-?}
muted=""; cls="ok"
[[ "$raw" == *MUTED* ]] && { muted=" muted"; cls="alert"; }
desc=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed -n 's/.*node.description = "\(.*\)".*/\1/p' | head -1)
desc=${desc:-default sink}
short=$(printf '%s' "$desc" | cut -c1-22)

emit "$G_SPEAKER ${vol}%${muted} · $short" "$cls" "Output: $desc · ${vol}%${muted} · click: cycle sink · scroll: volume"
