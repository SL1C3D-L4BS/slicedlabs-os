#!/usr/bin/env bash
# SlicedLabs · body · © 2026 SlicedLabs
# Running-game detection — signal +1.
[[ "$(cat "$HOME/.cache/cockpit-active-tab" 2>/dev/null)" == "gaming" ]] || { echo ""; exit 0; }

proc=$(pgrep -fa 'wine64-preloader|wine-preloader|gamescope-pid|GAMESCOPE' 2>/dev/null | head -1 || true)
if [[ -n "$proc" ]]; then
    name=$(awk '{for(i=NF;i>=1;i--) if($i ~ /\.exe$/){print $i; exit}}' <<<"$proc")
    name="${name##*/}"
    printf '{"text":" %s","class":"playing","tooltip":"%s"}\n' "${name:-running}" "$(echo "$proc" | head -c 200)"
else
    printf '{"text":" IDLE","class":"idle","tooltip":"No game running"}\n'
fi
