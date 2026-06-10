#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# easyeffects.sh — EasyEffects processing-chain state (media HUD).
set -u
source "$HOME/.config/quickshell/cockpit/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "media" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

if pgrep -x easyeffects >/dev/null 2>&1; then
    preset=$(gsettings get org.gnome.easyeffects last-used-output-preset 2>/dev/null | tr -d "'" || true)
    [[ -z "$preset" || "$preset" == "null" ]] && preset="WaveXLR-Pro"
    emit "$G_MIC $preset" ok "EasyEffects running · output preset: $preset"
else
    emit "$G_MIC off" empty "EasyEffects not running"
fi
