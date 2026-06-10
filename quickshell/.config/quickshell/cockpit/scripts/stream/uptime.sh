#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# uptime.sh — Recording / streaming elapsed time.
#
# Queries OBS WebSocket for the more authoritative recording/streaming
# duration (millis since output started). Hidden when neither active.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "stream" ]] || { echo ""; exit 0; }

if ! pgrep -x obs >/dev/null; then
    printf '{"text":"󱎫 ·","class":"empty","tooltip":"OBS not running"}\n'; exit 0
fi

rec=$(obs-ws-query GetRecordStatus 2>/dev/null || echo "")
str=$(obs-ws-query GetStreamStatus 2>/dev/null || echo "")
[[ -z "$rec$str" ]] && { printf '{"text":"󱎫 ·","class":"empty","tooltip":"OBS WebSocket unavailable"}\n'; exit 0; }

# Pick the longer-running output; OBS returns outputDuration in ms.
rec_dur=$(echo "$rec" | jq -r 'if .outputActive then (.outputDuration // 0) else 0 end' 2>/dev/null || echo 0)
str_dur=$(echo "$str" | jq -r 'if .outputActive then (.outputDuration // 0) else 0 end' 2>/dev/null || echo 0)

dur=$rec_dur
label="REC"
if (( str_dur > rec_dur )); then
    dur=$str_dur
    label="LIVE"
fi

if (( dur == 0 )); then
    printf '{"text":"󱎫 idle","class":"empty","tooltip":"not recording or streaming"}\n'; exit 0
fi

# ms → h:mm:ss
total=$((dur / 1000))
h=$((total / 3600))
m=$(((total / 60) % 60))
s=$((total % 60))
if (( h > 0 )); then
    elapsed=$(printf '%d:%02d:%02d' "$h" "$m" "$s")
else
    elapsed=$(printf '%d:%02d' "$m" "$s")
fi

cls="recording"; [[ "$label" == "LIVE" ]] && cls="live"
printf '{"text":"󱎫 %s %s","class":"%s","tooltip":"%s elapsed for %s"}\n' "$label" "$elapsed" "$cls" "$elapsed" "$label"
