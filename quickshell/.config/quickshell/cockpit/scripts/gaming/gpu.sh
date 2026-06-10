#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# AMD GPU stats — signal +2.
[[ "$(cat "$HOME/.cache/cockpit-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

CARD=/sys/class/drm/card1/device
[[ -f "$CARD/gpu_busy_percent" ]] || CARD=/sys/class/drm/card0/device

util=$(cat "$CARD/gpu_busy_percent" 2>/dev/null || echo 0)
vram_used_raw=$(cat "$CARD/mem_info_vram_used" 2>/dev/null || echo 0)
vram_total_raw=$(cat "$CARD/mem_info_vram_total" 2>/dev/null || echo 1)
temp_raw=$(cat "$CARD"/hwmon/*/temp1_input 2>/dev/null | head -1)

util=${util:-0}
temp=$(( ${temp_raw:-0} / 1000 ))
vram_used=$(( ${vram_used_raw:-0} / 1048576 ))
vram_total=$(( ${vram_total_raw:-1} / 1048576 ))

class="ok"
(( temp >= 80 )) && class="critical"

printf '{"text":"󰢮 %d%% %d°C %d/%dM","class":"%s","tooltip":"AMD %s — radv"}\n' \
    "$util" "$temp" "$vram_used" "$vram_total" "$class" \
    "$(basename "$(dirname "$CARD")")"
