#!/usr/bin/env bash
# link.sh — instantaneous throughput on the default-route iface (net HUD).
# Samples /proc/net/dev across calls; caches the prior sample in /tmp.
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "net" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
[[ -z "$iface" ]] && { emit "$G_NET_DOWN · offline" empty "no default route"; exit 0; }

CACHE="/tmp/waybar-net-link-$iface"
read -r rx_now tx_now < <(awk -v ifn="$iface:" '$1 == ifn {print $2, $10; exit}' /proc/net/dev)
rx_now=${rx_now:-0}; tx_now=${tx_now:-0}; now_t=$(date +%s)
rx_rate=0; tx_rate=0
if [[ -f "$CACHE" ]]; then
    read -r prev_t prev_rx prev_tx < "$CACHE"
    dt=$(( now_t - prev_t ))
    if (( dt > 0 && dt < 30 )); then rx_rate=$(( (rx_now - prev_rx) / dt )); tx_rate=$(( (tx_now - prev_tx) / dt )); fi
fi
printf '%d %d %d\n' "$now_t" "$rx_now" "$tx_now" > "$CACHE"

human() { local b=$1; if (( b >= 1048576 )); then awk "BEGIN{printf \"%.1fM\", $b/1048576}"; elif (( b >= 1024 )); then printf '%dK' "$(( b / 1024 ))"; else printf '%dB' "$b"; fi; }
emit "$G_NET_DOWN $(human "$rx_rate") $G_NET_UP $(human "$tx_rate")" ok "$iface · rx $(human "$rx_rate")/s · tx $(human "$tx_rate")/s"
