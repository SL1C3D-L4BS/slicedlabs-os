#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# pomo.sh — current uair Pomodoro state (AI HUD). Click: toggle uair.
set -u
source "$HOME/.config/quickshell/cockpit/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "ai" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

if ! command -v uairctl >/dev/null 2>&1; then emit "$G_POMO n/a" empty "uair not installed"; exit 0; fi

name=$(uairctl fetch '{name}' 2>/dev/null || echo "")
time=$(uairctl fetch '{time}' 2>/dev/null || echo "")
[[ -z "$name$time" ]] && { emit "$G_POMO idle" paused "uair idle · click: toggle"; exit 0; }

cls="paused"
case "${name,,}" in
    *work*|*focus*) cls="work" ;;
    *break*|*rest*) cls="break" ;;
esac
emit "$G_POMO ${name:-pomo} ${time}" "$cls" "uair: ${name:-?} ${time} · click: toggle"
