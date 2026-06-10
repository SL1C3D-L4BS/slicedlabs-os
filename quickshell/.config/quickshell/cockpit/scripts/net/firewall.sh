#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# firewall.sh — nftables firewall state (net HUD). Uses systemctl is-ENABLED,
# not is-active: nftables.service is a ONESHOT that loads /etc/nftables.conf at
# boot then exits, so is-active reads "inactive" even while the ruleset is
# enforced. is-enabled is the truthful, no-root proxy.
set -u
source "$HOME/.config/quickshell/cockpit/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "net" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

state=$(systemctl is-enabled nftables 2>/dev/null || true)
case "$state" in
    enabled|enabled-runtime|static)
        emit "$G_FIREWALL on"  ok    "nftables enabled — default-deny ruleset loads at boot" ;;
    *)  emit "$G_FIREWALL off" alert "nftables $state — firewall not enforced" ;;
esac
