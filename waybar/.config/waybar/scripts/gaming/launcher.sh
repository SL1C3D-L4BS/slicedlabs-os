#!/usr/bin/env bash
# Quick-launcher chip (clickable) — signal +7.
[[ "$(cat "$HOME/.cache/waybar-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

printf '{"text":"󰊴 PLAY","tooltip":"Click: gaming launcher menu (Mod+Shift+G)"}\n'
