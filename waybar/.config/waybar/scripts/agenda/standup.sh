#!/usr/bin/env bash
# standup.sh — countdown to the next daily standup (agenda HUD).
# Standup time read from ~/.config/slicedlabs/standup-time (HH:MM, default 09:30).
# Click posts the standup via ~/.local/bin/standup-post.
set -u
source "$HOME/.config/waybar/scripts/lib/glyphs.sh"

active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "agenda" ]] || { echo ""; exit 0; }

emit() { jq -cn --arg t "$1" --arg c "$2" --arg tt "$3" '{text:$t,class:$c,tooltip:$tt}'; }

hhmm=$(cat "$HOME/.config/slicedlabs/standup-time" 2>/dev/null || echo "09:30")
now=$(date +%s)
target=$(date -d "today $hhmm" +%s 2>/dev/null || echo "$now")
(( target <= now )) && target=$(date -d "tomorrow $hhmm" +%s 2>/dev/null || echo "$now")
diff=$(( target - now )); h=$(( diff / 3600 )); m=$(( (diff % 3600) / 60 ))

cls="ok"; (( diff < 900 )) && cls="alert"
if (( h > 0 )); then disp="${h}h${m}m"; else disp="${m}m"; fi
emit "$G_BELL standup $disp" "$cls" "next standup $hhmm (in $disp) · click: post standup"
