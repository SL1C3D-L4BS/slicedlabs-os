#!/usr/bin/env bash
# scene.sh — OBS current scene name chip.
#
# Separate from stream/obs.sh (which surfaces idle/REC/LIVE state) so the
# scene name can be styled independently. Requires obs-websocket plugin and
# obs-ws-query binary; falls back to "OBS only" when websocket unavailable.
set -eu

# Scroll actions (wired from waybar): cycle the OBS program scene. Best-effort
# via WebSocket — silently no-ops if obs-ws-query can't issue set requests.
case "${1:-}" in
  --next|--prev)
    cur=$(obs-ws-query GetCurrentProgramScene 2>/dev/null | jq -r '.currentProgramSceneName // ""' 2>/dev/null || echo "")
    mapfile -t scenes < <(obs-ws-query GetSceneList 2>/dev/null | jq -r '.scenes[].sceneName' 2>/dev/null | tac)
    n=${#scenes[@]}; (( n == 0 )) && exit 0
    idx=0; for i in "${!scenes[@]}"; do [[ "${scenes[$i]}" == "$cur" ]] && idx=$i; done
    if [[ "$1" == "--next" ]]; then idx=$(( (idx + 1) % n )); else idx=$(( (idx - 1 + n) % n )); fi
    obs-ws-query SetCurrentProgramScene "${scenes[$idx]}" >/dev/null 2>&1 || true
    exit 0 ;;
esac

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "stream" ]] || { echo ""; exit 0; }

if ! pgrep -x obs >/dev/null 2>&1; then
    printf '{"text":"󰋩 ·","class":"empty","tooltip":"OBS not running"}\n'; exit 0
fi

scene_json=$(obs-ws-query GetCurrentProgramScene 2>/dev/null || echo "")
if [[ -z "$scene_json" ]]; then
    printf '{"text":"󰋩 · scene?","class":"empty","tooltip":"enable obs-websocket plugin for scene name"}\n'
    exit 0
fi

scene_name=$(echo "$scene_json" | jq -r '.currentProgramSceneName // ""' 2>/dev/null || echo "")
if [[ -z "$scene_name" ]]; then
    printf '{"text":"󰋩 · ?","class":"empty","tooltip":"OBS reported no current scene"}\n'
else
    printf '{"text":"󰋩 %s","class":"info","tooltip":"OBS scene: %s"}\n' "$scene_name" "$scene_name"
fi
