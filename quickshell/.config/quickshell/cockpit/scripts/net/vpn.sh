#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# vpn.sh — WireGuard interface state (net HUD). No root needed (ip link only).
set -u
source "$HOME/.config/quickshell/cockpit/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "net" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

ifs=$(ip -j link show type wireguard 2>/dev/null | jq -r '.[].ifname' 2>/dev/null || true)
if [[ -z "$ifs" ]]; then
    emit "$G_VPN off" empty "no WireGuard interface up"
else
    first=$(head -1 <<<"$ifs")
    count=$(wc -l <<<"$ifs")
    emit "$G_VPN $first" ok "WireGuard up: $(tr '\n' ' ' <<<"$ifs")(${count} iface)"
fi
