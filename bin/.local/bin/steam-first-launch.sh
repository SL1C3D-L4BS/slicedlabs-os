#!/usr/bin/env bash
# steam-first-launch.sh — Phase 4 helper.
#
# Two stages, picks up where you are:
#   • No ~/.steam yet → launches Steam, prints next steps, exits.
#   • ~/.steam exists & no Steam running → installs latest GE-Proton non-interactively.
#
# Re-runnable. Idempotent. Use --force to overwrite an existing GE-Proton.

set -euo pipefail

force=""
[[ "${1:-}" == "--force" ]] && force="--force"

STEAM_ROOT="$HOME/.steam/root"
COMPAT_DIR="$STEAM_ROOT/compatibilitytools.d"

# Stage 1 — first-ever launch.
if [[ ! -d "$STEAM_ROOT" ]]; then
    cat <<'BANNER'

╭─────────────────────────────────────────────────────────────╮
│  Stage 1 — First Steam launch                                │
│  • Steam will open. Log in.                                  │
│  • Wait for the Steam runtime download to finish (~300 MB).  │
│  • Quit Steam cleanly (Steam menu → Exit).                   │
│  • Then re-run this script to install GE-Proton.             │
╰─────────────────────────────────────────────────────────────╯

BANNER
    notify-send -a "Gaming setup" "Steam first launch" "Log in, let the runtime download, then exit Steam." 2>/dev/null || true
    exec steam
fi

# Stage 2 — Steam has run at least once. Refuse if it's still running.
if pgrep -x steam >/dev/null; then
    echo "✗ Steam is still running. Exit Steam (Steam menu → Exit) before installing GE-Proton."
    echo "  protonup-rs writes into Steam's compatibilitytools.d and can race with Steam."
    exit 1
fi

mkdir -p "$COMPAT_DIR"

echo "→ Installing latest GE-Proton into $COMPAT_DIR …"
protonup-rs -q $force --tool GEProton --version latest --for steam

echo
echo "Installed compatibility tools:"
ls -1 "$COMPAT_DIR" 2>/dev/null | sed 's/^/  • /' || echo "  (none — installation may have failed)"

cat <<'NEXT'

Next:
  1. Launch Steam.
  2. Settings → Compatibility → "Run other titles with…" → pick the
     newest GE-Proton-* entry.
  3. (Optional) per-game: right-click → Properties → Compatibility.

For the verification game (Phase 12), pick any ProtonDB Platinum title:
  Portal 2, Hades, Hollow Knight, Stardew Valley, Celeste.
NEXT
