#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# failed-units.sh — count of failed systemd units (system + user scopes).
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "monitoring" ]] || { echo ""; exit 0; }

sys=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
usr=$(systemctl --user --failed --no-legend 2>/dev/null | wc -l)
total=$(( sys + usr ))

if (( total == 0 )); then
    printf '{"text":"󰸞 ok","class":"ok","tooltip":"No failed units (system + user)"}\n'
else
    printf '{"text":"󰀦 %d failed","class":"critical","tooltip":"system: %d failed · user: %d failed — systemctl --failed for details"}\n' "$total" "$sys" "$usr"
fi
