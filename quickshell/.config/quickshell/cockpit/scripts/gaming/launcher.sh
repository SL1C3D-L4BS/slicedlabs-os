#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# Quick-launcher chip (clickable) — signal +7.
[[ "$(cat "$HOME/.cache/cockpit-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

printf '{"text":"󰊴 PLAY","tooltip":"Click: gaming launcher menu (Mod+Shift+G)"}\n'
