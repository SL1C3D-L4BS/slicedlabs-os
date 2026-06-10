#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# build.sh — coding tab build status chip. Reads ~/.cache/engine-build-status
# which is written by `cargo-build-status` (the wrapper that fronts cargo
# build / test / check in this workstation).
#
# Schema (one line of JSON):
#   {"state":"ok|fail|building","duration_s":1.4,"errors":0,"warnings":0,"target":"debug","ts":...}

set -eu

tab_id="coding"
active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

status_file="${XDG_CACHE_HOME:-$HOME/.cache}/engine-build-status"
if [[ ! -f "$status_file" ]]; then
  printf '{"text":"… no build","class":"info","tooltip":"run cargo-build-status to populate"}\n'
  exit 0
fi

state=$(jq -r .state            < "$status_file" 2>/dev/null || echo "?")
dur=$(  jq -r .duration_s       < "$status_file" 2>/dev/null || echo "0")
err=$(  jq -r .errors           < "$status_file" 2>/dev/null || echo "0")
warn=$( jq -r .warnings         < "$status_file" 2>/dev/null || echo "0")
target=$(jq -r .target          < "$status_file" 2>/dev/null || echo "?")
ts=$(   jq -r .ts               < "$status_file" 2>/dev/null || echo "0")

case "$state" in
  ok)       text="✓ built ${dur}s ${target}";        class="ok"       ;;
  fail)     text="✗ ${err} errors ${target}";         class="critical" ;;
  building) text="… building ${target}";              class="warning"  ;;
  *)        text="? unknown";                          class="info"     ;;
esac

[[ "$warn" -gt 0 && "$state" == "ok" ]] && text+=" ⚠${warn}"

age=$(( $(date +%s) - ${ts:-0} ))
tooltip="state: $state\nlast build: ${age}s ago\nerrors: $err  warnings: $warn  target: $target"
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
