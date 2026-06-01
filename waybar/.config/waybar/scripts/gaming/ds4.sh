#!/usr/bin/env bash
# DualShock 4 / DualSense battery — signal +5.
[[ "$(cat "$HOME/.cache/waybar-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

# hid-playstation exposes ps-controller-battery-*; older hid-sony uses sony_controller_battery_*.
pad=""
for p in /sys/class/power_supply/ps-controller-battery-* /sys/class/power_supply/sony_controller_battery_*; do
    [[ -d "$p" ]] && { pad="$p"; break; }
done

if [[ -z "$pad" ]]; then
    printf '{"text":"","tooltip":"No DS4 connected"}\n'
    exit 0
fi

cap=$(cat "$pad/capacity" 2>/dev/null || echo 0)
stat=$(cat "$pad/status" 2>/dev/null || echo Unknown)

class="ok"
(( cap < 20 )) && class="critical"

printf '{"text":"󰊴 %d%%","class":"%s","tooltip":"DS4: %s"}\n' "$cap" "$class" "$stat"
