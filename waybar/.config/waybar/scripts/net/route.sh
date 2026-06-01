#!/usr/bin/env bash
# route.sh — default route iface + local IP + (cached) public IP (net HUD).
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "net" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
if [[ -z "$iface" ]]; then emit "$G_ROUTE offline" critical "no default route"; exit 0; fi
lip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)

# Public IP — cached 5 min to avoid hammering on the 30s interval.
CACHE="/tmp/waybar-pubip"; TTL=300; pub=""
if [[ -f "$CACHE" ]] && (( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) < TTL )); then
    pub=$(cat "$CACHE" 2>/dev/null)
else
    pub=$(curl -fsS --max-time 2 https://ifconfig.me 2>/dev/null || echo "")
    [[ -n "$pub" ]] && printf '%s' "$pub" > "$CACHE"
fi

emit "$G_ROUTE $iface ${lip:-?}" ok "iface: $iface · local: ${lip:-?} · public: ${pub:-(unknown)} · click: addrs+routes"
