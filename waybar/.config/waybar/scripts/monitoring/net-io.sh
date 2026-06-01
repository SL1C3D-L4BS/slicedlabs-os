#!/usr/bin/env bash
# net-io.sh — instantaneous network throughput on the default route.
#
# Reads /proc/net/dev twice 1s apart, diffs rx/tx bytes on the active IF
# (default-route iface). Caches the prior sample in /tmp.
set -eu

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "monitoring" ]] || { echo ""; exit 0; }

iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
if [[ -z "$iface" ]]; then
    printf '{"text":"󰣽 · offline","class":"empty","tooltip":"no default route"}\n'
    exit 0
fi

CACHE="/tmp/waybar-net-io-$iface"

read_bytes() {
    awk -v ifn="$iface:" '$1 == ifn {print $2, $10; exit}' /proc/net/dev
}

now_t=$(date +%s)
read -r rx_now tx_now < <(read_bytes)
rx_now=${rx_now:-0}; tx_now=${tx_now:-0}

if [[ -f "$CACHE" ]]; then
    read -r prev_t prev_rx prev_tx < "$CACHE"
    dt=$(( now_t - prev_t ))
    if (( dt > 0 && dt < 30 )); then
        rx_rate=$(( (rx_now - prev_rx) / dt ))
        tx_rate=$(( (tx_now - prev_tx) / dt ))
    fi
fi
printf '%d %d %d\n' "$now_t" "$rx_now" "$tx_now" > "$CACHE"

humanize() {
    local b=$1
    if   (( b >= 1048576 )); then printf '%.1fM' "$(awk "BEGIN{print $b/1048576}")"
    elif (( b >= 1024 ));    then printf '%dK' "$(( b / 1024 ))"
    else                          printf '%dB' "$b"
    fi
}

rx=$(humanize "${rx_rate:-0}")
tx=$(humanize "${tx_rate:-0}")

printf '{"text":"󰇚 %s 󰕒 %s","class":"ok","tooltip":"%s · rx %s/s tx %s/s"}\n' \
    "$rx" "$tx" "$iface" "$rx" "$tx"
