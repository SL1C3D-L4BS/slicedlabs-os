#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# next.sh — next calendar event in the coming 24h (agenda HUD), via khal.
set -u
source "$HOME/.config/quickshell/cockpit/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "agenda" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

if ! command -v khal >/dev/null 2>&1; then emit "$G_AGENDA n/a" empty "khal not installed"; exit 0; fi

line=$(khal list now 24h --format '{start-time} {title}' 2>/dev/null | grep -vE '^(Today|Tomorrow|$)' | head -1)
[[ -z "$line" ]] && { emit "$G_AGENDA clear" ok "no events in the next 24h"; exit 0; }

short=$(printf '%s' "$line" | cut -c1-40)
emit "$G_AGENDA $short" info "next: $line"
