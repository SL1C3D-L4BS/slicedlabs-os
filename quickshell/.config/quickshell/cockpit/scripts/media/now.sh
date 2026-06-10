#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# now.sh — MPRIS now-playing chip (media HUD). Click: play/pause; scroll: seek.
set -u
source "$HOME/.config/quickshell/cockpit/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "media" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

if ! command -v playerctl >/dev/null 2>&1; then
    emit "$G_MEDIA n/a" empty "playerctl not installed"; exit 0
fi

status=$(playerctl status 2>/dev/null || true)
case "$status" in
    Playing) g="$G_PLAY";  cls="playing" ;;
    Paused)  g="$G_PAUSE"; cls="ok" ;;
    *)       emit "$G_MEDIA ·" empty "no active media player"; exit 0 ;;
esac

artist=$(playerctl metadata artist 2>/dev/null || true)
title=$(playerctl metadata title 2>/dev/null || true)
label="${title:-unknown}"
[[ -n "$artist" ]] && label="$artist — $title"
short=$(printf '%s' "$label" | cut -c1-44)

emit "$g $short" "$cls" "$label · click: play/pause · scroll: prev/next"
