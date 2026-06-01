#!/usr/bin/env bash
# MangoHud toggle chip (clickable) — signal +6.
[[ "$(cat "$HOME/.cache/waybar-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

printf '{"text":"󰍛 HUD","tooltip":"Click: send F12 (toggles MangoHud in any focused game)"}\n'
