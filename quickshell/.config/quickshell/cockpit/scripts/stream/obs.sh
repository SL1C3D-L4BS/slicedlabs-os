#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# obs.sh — OBS state chip.
#
# Hierarchy of signals (from authoritative to fallback):
#   1. WebSocket (port 4455) GetRecordStatus / GetStreamStatus / GetCurrentProgramScene
#   2. pgrep — OBS process present (websocket not available / not enabled)
#   3. nothing — show "off"
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "stream" ]] || { echo ""; exit 0; }

if ! pgrep -x obs >/dev/null; then
    printf '{"text":"󰕧 · off","class":"empty","tooltip":"OBS not running"}\n'
    exit 0
fi

# Try websocket.
rec=$(obs-ws-query GetRecordStatus 2>/dev/null || echo "")
str=$(obs-ws-query GetStreamStatus 2>/dev/null || echo "")
scene=$(obs-ws-query GetCurrentProgramScene 2>/dev/null || echo "")

if [[ -z "$rec$str$scene" ]]; then
    printf '{"text":"󰕧 on","class":"ok","tooltip":"OBS running — enable WebSocket in OBS for REC/LIVE state"}\n'
    exit 0
fi

rec_active=$(echo "$rec" | jq -r '.outputActive // false' 2>/dev/null || echo false)
str_active=$(echo "$str" | jq -r '.outputActive // false' 2>/dev/null || echo false)
scene_name=$(echo "$scene" | jq -r '.currentProgramSceneName // ""' 2>/dev/null || echo "")

if [[ "$rec_active" == "true" && "$str_active" == "true" ]]; then
    state_text="LIVE+REC"; cls="live"
elif [[ "$str_active" == "true" ]]; then
    state_text="LIVE"; cls="live"
elif [[ "$rec_active" == "true" ]]; then
    state_text="REC"; cls="recording"
else
    state_text="idle"; cls="ok"
fi

label="$state_text"
[[ -n "$scene_name" ]] && label+="  ${scene_name}"

printf '{"text":"󰕧 %s","class":"%s","tooltip":"OBS — scene: %s · recording: %s · streaming: %s"}\n' \
    "$label" "$cls" "${scene_name:-?}" "$rec_active" "$str_active"
