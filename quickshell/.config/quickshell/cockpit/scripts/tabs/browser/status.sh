#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# status.sh — browser tab presence/tab-count chip for Zen Browser.
# Detection order:
#   1. Niri window matching "zen" — show focused title (truncated)
#   2. Recovery file under ~/.config/zen/Profiles/*/sessionstore-backups/ — count tabs
#   3. Static "offline" placeholder

set -eu

tab_id="browser"
active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

title=""
if command -v niri >/dev/null 2>&1; then
  title=$(niri msg --json windows 2>/dev/null \
    | jq -r '.[] | select(.is_focused == true) | select(.app_id // "" | test("zen"; "i")) | .title' \
    | head -1)
fi
title="${title:-Zen}"
# Truncate noisy titles to ~40 chars (matches niri/window width budget).
[[ "${#title}" -gt 40 ]] && title="${title:0:39}…"

recovery=$(ls -1t "$HOME"/.config/zen/Profiles/*/sessionstore-backups/recovery.jsonlz4 2>/dev/null | head -1 || true)
tab_count="?"
if [[ -n "$recovery" && -f "$recovery" ]]; then
  # The recovery file is lz4-compressed JSON with a 4-char magic ("mozLz40").
  if command -v dejsonlz4 >/dev/null 2>&1; then
    tab_count=$(dejsonlz4 "$recovery" 2>/dev/null \
      | jq '[.windows[]?.tabs[]?] | length' 2>/dev/null || echo "?")
  fi
fi

printf '{"text":" %s · %s tabs","class":"info","tooltip":"title: %s\\ntabs: %s"}\n' \
  "$title" "$tab_count" "$title" "$tab_count"
