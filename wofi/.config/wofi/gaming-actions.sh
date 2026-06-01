#!/usr/bin/env bash
# gaming-actions.sh — Wofi-driven gaming actions menu.
#
# Invoked by Mod+G when already on the gaming workspace (see workspace-gaming-
# action wrapper). Replaces the two Waybar chips (mangohud-toggle, quick-
# launcher) that were dropped from the bar to honor the 5-chip information-
# density target.
#
# Wofi (vs fuzzel for ~/.config/gaming/menu.sh) — matches the rest of the
# workstation's launcher chrome (Wofi for everything that's keyboard-driven).
set -euo pipefail

choice=$(printf '%s\n' \
    "Steam" \
    "Steam Big Picture" \
    "Lutris" \
    "Heroic" \
    "Bottles" \
    "Toggle GameMode" \
    "Toggle gamescope wrap (next launch)" \
    "Toggle MangoHud (F12)" \
    | wofi --dmenu --prompt "PLAY: " --width 480 --height 360 --insensitive)

case "$choice" in
    "Steam")                  steam & ;;
    "Steam Big Picture")      steam -bigpicture & ;;
    "Lutris")                 lutris & ;;
    "Heroic")                 heroic & ;;
    "Bottles")                bottles & ;;
    "Toggle GameMode")        "$HOME/.config/gaming/gamemode-toggle.sh" ;;
    "Toggle gamescope wrap (next launch)")
        # Flag file consumed by gaming launcher wrappers (Lutris/Heroic) when
        # spawning subsequent processes. Wrappers honor presence/absence of
        # this file to choose between bare wayland and gamescope embed.
        FLAG="${XDG_CACHE_HOME:-$HOME/.cache}/gamescope-wrap"
        if [[ -f "$FLAG" ]]; then
            rm -f "$FLAG"
            notify-send "Gaming" "gamescope wrap: OFF for next launch"
        else
            touch "$FLAG"
            notify-send "Gaming" "gamescope wrap: ON for next launch"
        fi
        ;;
    "Toggle MangoHud (F12)")  ydotool key 88 ;;
esac
