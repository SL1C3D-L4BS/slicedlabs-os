#!/usr/bin/env bash
# First-boot choreography for the live SlicedLabs OS ISO (runs once from ~/.zlogin).
# The replicability ladder rung "Try": boot → bootstrap → Welcome, zero risk to the
# host (it's a live ISO / VM). The PUBLIC showcase repo is cloned (never the private
# control-plane), so nothing proprietary ships on the ISO.
set -uo pipefail
PUBLIC_REPO="${SLICEDLABS_REPO:-https://github.com/SL1C3D-L4BS/slicedlabs-os.git}"
STAMP=/root/.slicedlabs-firstboot-done
[[ -f $STAMP ]] && exit 0

clear
echo "  Bringing up SlicedLabs OS — one moment…"
if [[ ! -d /root/.dotfiles ]]; then
    # Non-interactive clone: a missing / unpublished / private repo must FAIL FAST, never
    # hang on a git credential prompt (the showcase repo may not be public yet — the
    # interactive prompt is NOT silenced by 2>/dev/null, so it would block the live boot).
    if ! GIT_TERMINAL_PROMPT=0 git -c credential.helper= clone --depth 1 "$PUBLIC_REPO" /root/.dotfiles 2>/dev/null; then
        echo "  showcase repo not reachable yet — booting the live base only."
        echo "  (publish SL1C3D-L4BS/slicedlabs-os, or boot with SLICEDLABS_REPO=<url>, then re-login)"
    fi
fi
if [[ -x /root/.dotfiles/bootstrap.sh ]]; then
    bash /root/.dotfiles/bootstrap.sh --from 0 2>&1 | tail -20 || true
fi
touch "$STAMP"

# Hand off to the desktop (niri launches the cockpit via its user units); fall back
# to the Welcome page on a bare TTY so the first thing a tester sees is the map.
if command -v slicedlabs >/dev/null 2>&1; then slicedlabs welcome || true; fi
command -v niri >/dev/null 2>&1 && exec niri
