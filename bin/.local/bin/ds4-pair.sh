#!/usr/bin/env bash
# SlicedLabs · tools · © 2026 SlicedLabs
# ds4-pair.sh — Phase 9 helper for DualShock 4 / DualSense Bluetooth pairing.
#
# USB pad? You don't need this — plug in the USB cable. The hid_playstation
# module is already loaded; it shows up as /dev/input/jsX immediately.
#
# This script scripts the bluetoothctl steps the user would otherwise type by
# hand. It:
#   1. Powers Bluetooth on, registers the default agent.
#   2. Tells you when to put the pad in pairing mode (hold PS + Share).
#   3. Scans for ~25 s, picks the first PlayStation-class controller it sees,
#      and runs pair / trust / connect.
#
# Cancel with Ctrl-C at any time.

set -euo pipefail

if ! command -v bluetoothctl >/dev/null; then
    echo "✗ bluetoothctl not installed (pacman -S bluez-utils)"; exit 1
fi
if ! systemctl is-active --quiet bluetooth; then
    echo "→ Starting bluetooth.service (requires sudo)…"
    sudo systemctl start bluetooth
fi

cat <<'BANNER'

╭───────────────────────────────────────────────────────────╮
│  DualShock 4 / DualSense — Bluetooth pairing              │
│                                                            │
│  Step 1: Make sure the pad is OFF (PS light dark).         │
│  Step 2: When prompted below, hold PS + Share for ~5 s     │
│          until the lightbar flashes RAPIDLY (2 Hz).        │
│  Step 3: This script will scan, pair, trust, and connect.  │
╰───────────────────────────────────────────────────────────╯
BANNER

bluetoothctl -- power on >/dev/null
bluetoothctl -- agent on >/dev/null 2>&1 || true
bluetoothctl -- default-agent >/dev/null 2>&1 || true

read -r -p "[Enter] when you're ready to hold PS+Share … "

echo "→ Scanning for 25 s (hold PS+Share NOW)…"
bluetoothctl --timeout 25 scan on >/dev/null 2>&1 || true

# bluetoothctl 'devices' lists everything ever seen; filter to PlayStation pads.
mapfile -t found < <(
    bluetoothctl devices \
        | awk '/Wireless Controller|DualSense|DualShock/ { print $2 }'
)

if (( ${#found[@]} == 0 )); then
    echo "✗ No DualShock/DualSense controller discovered."
    echo "  • Confirm the lightbar was flashing rapidly during the scan."
    echo "  • If it was solid or slow-blink, the pad wasn't in pairing mode."
    echo "  • Sometimes a second attempt works — re-run this script."
    exit 1
fi

# If a paired one already exists, pick the unpaired one preferentially.
mac=""
for m in "${found[@]}"; do
    if ! bluetoothctl info "$m" 2>/dev/null | grep -q 'Paired: yes'; then
        mac="$m"; break
    fi
done
mac="${mac:-${found[0]}}"

echo "→ Found controller at $mac"

bluetoothctl pair    "$mac" || { echo "✗ pair failed";    exit 1; }
bluetoothctl trust   "$mac" || true
bluetoothctl connect "$mac" || { echo "✗ connect failed"; exit 1; }

sleep 2

# Verify hid_playstation picked it up.
if compgen -G '/sys/class/power_supply/ps-controller-battery-*' >/dev/null; then
    for bat in /sys/class/power_supply/ps-controller-battery-*; do
        printf '✓ Connected. Battery: %s%% (%s)\n' \
            "$(<"$bat/capacity")" "$(<"$bat/status")"
    done
elif [[ -e /dev/input/js0 ]]; then
    echo "✓ Connected (joystick device present, battery node not yet exposed)."
else
    echo "✓ bluetoothctl reports connected, but no battery node found."
    echo "  Give it a few seconds, then check: ls /sys/class/power_supply/ps-controller-battery-*"
fi

cat <<'POST'

Next:
  • In Steam: Settings → Controller → enable "PlayStation Configuration
    Support" (so games see it as a Steam Input pad with DS4 button glyphs).
  • Waybar's DS4 chip refreshes every 30 s — or run:
      pkill -SIGRTMIN+8 waybar
POST
