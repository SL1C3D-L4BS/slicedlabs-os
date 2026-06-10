#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# mic.sh — EasyEffects-processed mic chain state.
#
# Source name comes from the [[streaming-setup]] convention:
# `easyeffects_source` is the post-processed sink that OBS reads.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "stream" ]] || { echo ""; exit 0; }

SRC="easyeffects_source"

if ! command -v pactl >/dev/null; then
    printf '{"text":"󰍮 · n/a","class":"empty","tooltip":"pactl not installed"}\n'
    exit 0
fi

if ! pactl list short sources 2>/dev/null | awk '{print $2}' | grep -qx "$SRC"; then
    printf '{"text":"󰍮 · no mic","class":"empty","tooltip":"PulseAudio source \"%s\" not present — EasyEffects not running?"}\n' "$SRC"
    exit 0
fi

muted=$(pactl get-source-mute "$SRC" 2>/dev/null | awk '{print $2}')
volume=$(pactl get-source-volume "$SRC" 2>/dev/null | awk '/Volume:/ {print $5; exit}')

if [[ "$muted" == "yes" ]]; then
    printf '{"text":"󰍭 MUTE","class":"alert","tooltip":"%s muted — OBS hears silence (vol %s)"}\n' "$SRC" "${volume:-?}"
else
    printf '{"text":"󰍬 LIVE","class":"ok","tooltip":"%s live · vol %s"}\n' "$SRC" "${volume:-?}"
fi
