#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# GameMode active state — signal +4.
[[ "$(cat "$HOME/.cache/cockpit-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

if gamemoded -s 2>/dev/null | grep -q "is active"; then
    printf '{"text":"󰜎 ON","class":"on","tooltip":"GameMode active"}\n'
else
    printf '{"text":"󰜎 OFF","class":"off","tooltip":"GameMode idle"}\n'
fi
