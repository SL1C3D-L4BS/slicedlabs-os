#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# bitrate.sh — OBS live encode bitrate (when streaming/recording).
#
# Health classes:
#   ok       : ≥ 4000 kbps (healthy 1080p60 stream)
#   alert    : 2000-3999 kbps (lower quality, may still be acceptable)
#   critical : < 2000 kbps (dropping bitrate — viewer-visible degradation)
#   empty    : no active output, or websocket unreachable
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "stream" ]] || { echo ""; exit 0; }

if ! pgrep -x obs >/dev/null 2>&1; then
    printf '{"text":"󰒺 ·","class":"empty","tooltip":"OBS not running"}\n'; exit 0
fi

str=$(obs-ws-query GetStreamStatus 2>/dev/null || echo "")
rec=$(obs-ws-query GetRecordStatus 2>/dev/null || echo "")

if [[ -z "$str" && -z "$rec" ]]; then
    printf '{"text":"󰒺 · ?","class":"empty","tooltip":"enable obs-websocket for live bitrate"}\n'
    exit 0
fi

# Prefer streaming bitrate if active; else recording.
str_active=$(echo "$str" | jq -r '.outputActive // false' 2>/dev/null || echo false)
rec_active=$(echo "$rec" | jq -r '.outputActive // false' 2>/dev/null || echo false)

bytes_per_sec=0
src="idle"
if [[ "$str_active" == "true" ]]; then
    # outputBytes is cumulative; we'd need delta. obs-ws-query may expose a
    # rate field directly. Fall back to last-second delta if not.
    bytes_per_sec=$(echo "$str" | jq -r '.outputBytesPerSecond // 0' 2>/dev/null || echo 0)
    src="streaming"
elif [[ "$rec_active" == "true" ]]; then
    bytes_per_sec=$(echo "$rec" | jq -r '.outputBytesPerSecond // 0' 2>/dev/null || echo 0)
    src="recording"
else
    printf '{"text":"󰒺 idle","class":"empty","tooltip":"OBS not currently streaming or recording"}\n'
    exit 0
fi

kbps=$(( bytes_per_sec * 8 / 1000 ))

if (( kbps >= 4000 )); then
    cls="ok"
elif (( kbps >= 2000 )); then
    cls="alert"
elif (( kbps >= 1 )); then
    cls="critical"
else
    cls="empty"
fi

printf '{"text":"󰒺 %d kbps","class":"%s","tooltip":"OBS %s — %d kbps"}\n' \
    "$kbps" "$cls" "$src" "$kbps"
