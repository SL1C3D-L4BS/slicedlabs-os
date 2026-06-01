#!/usr/bin/env bash
# git.sh — coding tab git status chip. Reads the engine repo by default;
# override with ~/.cache/coding-workspace-path (one absolute path per line).

set -eu

tab_id="coding"
active=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab" 2>/dev/null || echo "")
[[ "$active" == "$tab_id" ]] || { echo ""; exit 0; }

repo=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/coding-workspace-path" 2>/dev/null || echo "$HOME/Projects/engine")
if [[ ! -d "$repo/.git" ]]; then
  printf '{"text":"no repo","class":"info","tooltip":"%s is not a git repo"}\n' "$repo"
  exit 0
fi

cd "$repo"
branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
# Ahead/behind vs upstream (if any).
ahead=0; behind=0
if up=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
  read -r ahead behind < <(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null | awk '{print $2, $1}') || true
fi
# Dirty count.
dirty=$(git status --porcelain 2>/dev/null | wc -l)

text=" ${branch}"
[[ "$ahead"  -gt 0 ]] && text+=" ↑$ahead"
[[ "$behind" -gt 0 ]] && text+=" ↓$behind"
[[ "$dirty"  -gt 0 ]] && text+=" ●$dirty"

class="info"
[[ "$dirty"  -gt 20 ]] && class="warning"
[[ "$behind" -gt 50 ]] && class="critical"

tooltip="repo: $repo\nbranch: $branch\nupstream: ${up:-none}\nahead: $ahead  behind: $behind  dirty: $dirty"
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
