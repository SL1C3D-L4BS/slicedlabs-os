#!/usr/bin/env bash
# team.sh — coding tab "active agents + today's spend" chip. Talks to
# Langfuse (if up) for spend; falls back to a static "team: idle" message.

set -eu

tab_id="coding"
active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

if ! command -v slicedlabs >/dev/null 2>&1; then
  printf '{"text":"team: offline","class":"info","tooltip":"slicedlabs CLI not on PATH"}\n'
  exit 0
fi

raw=$(slicedlabs cost today --format=json 2>/dev/null || echo "{}")
active_n=$(jq -r '.active // 0'   <<<"$raw" 2>/dev/null || echo 0)
spend=$(   jq -r '.total // 0'    <<<"$raw" 2>/dev/null || echo 0)
cap=$(     jq -r '.soft_cap // 25' <<<"$raw" 2>/dev/null || echo 25)

class="info"
if   awk "BEGIN { exit !($spend > $cap) }";       then class="critical"
elif awk "BEGIN { exit !($spend > $cap * 0.8) }"; then class="warning"
fi

printf '{"text":"team: %d · $%.2f","class":"%s","tooltip":"active agents: %d\\ntoday spend: $%.2f / $%.2f cap\\nclick: slicedlabs cost"}\n' \
  "$active_n" "$spend" "$class" "$active_n" "$spend" "$cap"
