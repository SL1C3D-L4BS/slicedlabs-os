#!/usr/bin/env bash
# header.sh — generic tab-header chip emitter.
#
# Usage: header.sh <tab-id> <label>
#   tab-id : engine | comms | stream | monitoring | gaming
#   label  : display text (e.g. "[ENGINE]", "GAMING", …)
#
# Emits a Waybar JSON chip iff the active tab equals <tab-id>; empty otherwise.
# The `class` attribute lets style.css colour each header per brand.

set -eu

tab_id="${1:?header.sh: missing tab-id}"
label="${2:?header.sh: missing label}"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

# Add the `urgent` class when waybard has flagged this tab (cap glows).
cls="$tab_id"
urgent=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-urgent" 2>/dev/null || echo "")
[[ " $urgent " == *" $tab_id "* ]] && cls="$tab_id urgent"

printf '{"text":"%s","class":"%s","tooltip":"Active tab: %s (workspace-driven)"}\n' \
    "$label" "$cls" "$tab_id"
