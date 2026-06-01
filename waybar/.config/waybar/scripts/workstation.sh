#!/usr/bin/env bash
# workstation.sh — always-visible left chip aggregating the most-actionable
# workstation signals into a single line:
#   <repo> · <branch> · <build> · <pomo>
#
# Left-click toggles uair; right-click opens lazygit (wired via waybar config).

set -eu

repo=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/coding-workspace-path" 2>/dev/null || echo "$HOME/Projects/engine")
repo_name=$(basename "$repo")

branch="?"
dirty_marker=""
if [[ -d "$repo/.git" ]]; then
  branch=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
  [[ $(git -C "$repo" status --porcelain 2>/dev/null | wc -l) -gt 0 ]] && dirty_marker="●"
fi

build_state="?"
status_file="${XDG_CACHE_HOME:-$HOME/.cache}/engine-build-status"
if [[ -f "$status_file" ]]; then
  build_state=$(jq -r .state < "$status_file" 2>/dev/null || echo "?")
fi
case "$build_state" in
  ok)       build_glyph="✓" ;;
  fail)     build_glyph="✗" ;;
  building) build_glyph="…" ;;
  *)        build_glyph="?" ;;
esac

pomo=""
if command -v uairctl >/dev/null 2>&1; then
  pomo=$(uairctl fetch '{name} {time}' 2>/dev/null || true)
fi
pomo_display="${pomo:-idle}"

# Class drives palette — workstation widget defaults to coding teal; critical
# build / overrun spend escalates.
class="info"
[[ "$build_state" == "fail" ]]         && class="critical"
[[ "$build_state" == "building" ]]     && class="warning"

text="${repo_name}${dirty_marker} · ${branch} · ${build_glyph} · ${pomo_display}"
tooltip="repo: $repo\nbranch: $branch\nbuild: $build_state\npomo: $pomo_display\nleft-click: uairctl toggle\nright-click: lazygit"

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
