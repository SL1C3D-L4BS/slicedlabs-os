#!/usr/bin/env bash
# build.sh — [ENGINE] bacon build status chip.
#
# Signals, in priority order:
#   1. bacon process running → ⏳ building (info)
#   2. engine-status JSON build_ok=true → ✓ ok (success class)
#   3. engine-status JSON build_ok=false (or missing) → ✗ stale (critical)
#
# Falls back gracefully when neither bacon nor engine-status are present.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "engine" ]] || { echo ""; exit 0; }

STATUS_JSON="${ENGINE_STATUS_OUT:-/tmp/engine-status.json}"

# 1. bacon running?
if pgrep -x bacon >/dev/null 2>&1; then
    printf '{"text":"⏳ build","class":"info","tooltip":"bacon is running — live build watch active"}\n'
    exit 0
fi

# 2/3. read engine-status JSON if present
if [[ -f "$STATUS_JSON" ]]; then
    build_ok=$(jq -r '.build_ok // false' "$STATUS_JSON" 2>/dev/null || echo false)
    crate=$(jq -r '.crate // ""' "$STATUS_JSON" 2>/dev/null || echo "")
    if [[ "$build_ok" == "true" ]]; then
        printf '{"text":"✓ build","class":"ok","tooltip":"target/ artifacts fresher than sources (crate: %s)"}\n' "${crate:-?}"
    else
        printf '{"text":"✗ stale","class":"critical","tooltip":"sources newer than build artifacts — run cargo build or bacon"}\n'
    fi
    exit 0
fi

# fallback — no signal available
printf '{"text":"· build","class":"empty","tooltip":"no engine-status JSON or bacon process"}\n'
