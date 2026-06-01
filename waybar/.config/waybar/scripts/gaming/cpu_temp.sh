#!/usr/bin/env bash
# CPU package temp — signal +3.
[[ "$(cat "$HOME/.cache/waybar-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

t=$(sensors -j 2>/dev/null \
    | jq -r '.["coretemp-isa-0000"]["Package id 0"]["temp1_input"] // 0' \
    | cut -d. -f1)

class="ok"
(( t >= 85 )) && class="critical"

printf '{"text":" %d°C","class":"%s","tooltip":"CPU package — coretemp"}\n' "$t" "$class"
