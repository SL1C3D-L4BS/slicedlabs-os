#!/usr/bin/env bash
# lib/scene.sh — registry-driven niri workspace "scene" realization.
#
# Sourced by `niri-workspace-launcher` (auto, on first focus) and `cockpit`
# (manual). SSOT: ~/.config/sliced-engine/workspaces.toml.
#
# Placement is DECLARATIVE: niri `open-on-workspace` window-rules (config.kdl)
# are the authority — an app's app_id maps it to its home workspace at map time,
# atomically, with no focus-steal. This file then: (1) starts backing services,
# (2) spawns each declared app if not already present, (3) runs an idempotent
# `move-window-to-workspace --focus false` BACKSTOP (a no-op when the rule already
# placed it; corrects any app whose rule misfires). Sizing is declarative too via
# each rule's `default-column-width`, so scene realization never yanks focus.
# REQUIREMENT: every app_id below MUST be the window's real app_id (verify with
# `niri msg windows`) — a wrong app_id silently breaks BOTH the rule and this
# backstop (the zen `app.zen_browser.zen` vs `zen` bug, fixed 2026-05-30).
# Idempotent: an app already present on its target workspace is never re-spawned
# (keyed on app_id + workspace_id, which survives a manually-closed window).

SCENE_REG="${SCENE_REG:-$HOME/.config/sliced-engine/workspaces.toml}"
SCENE_DRYRUN="${SCENE_DRYRUN:-0}"

# Boot-stage log — every realize step is journaled here so a login that fails to
# stage is DEBUGGABLE (the old behaviour sent all spawn output to /dev/null, which
# is why "nothing autostarted" left no trace). scene_log writes to the file AND to
# stderr, so `cockpit` still shows live progress while the file is `tail -f`-able.
SCENE_LOG="${SCENE_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/sliced/boot-stage.log}"
scene_log() {
    mkdir -p "$(dirname "$SCENE_LOG")" 2>/dev/null
    printf '%s  %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$SCENE_LOG" >&2
}

scene_meta_auto() {
    python3 - "$SCENE_REG" <<'PY' 2>/dev/null || true
import sys, tomllib
try:
    with open(sys.argv[1], "rb") as f: d = tomllib.load(f)
except OSError:
    sys.exit(0)
print("\n".join(d.get("meta", {}).get("auto", [])))
PY
}

scene_list() {
    python3 - "$SCENE_REG" <<'PY' 2>/dev/null || true
import sys, tomllib
with open(sys.argv[1], "rb") as f: d = tomllib.load(f)
auto = set(d.get("meta", {}).get("auto", []))
for ws, w in d.get("workspaces", {}).items():
    tag = "auto" if ws in auto else "on-demand"
    til = str(w.get("tiling", "auto"))
    apps = ", ".join(a.get("id", "?") for a in w.get("apps", [])) or w.get("delegate", "-")
    print(f"  {ws:<11} {w.get('output','?'):<9} {w.get('layout','?'):<9} {tag:<10} {til:<7} {apps}")
PY
}

_scene_field() {  # $1=ws $2=field -> value (or "")
    python3 - "$SCENE_REG" "$1" "$2" <<'PY' 2>/dev/null || true
import sys, tomllib
with open(sys.argv[1], "rb") as f: d = tomllib.load(f)
print(d.get("workspaces", {}).get(sys.argv[2], {}).get(sys.argv[3], ""))
PY
}

_scene_apps() {  # $1=ws -> lines "app_id|cmd|width|height" in column order
    python3 - "$SCENE_REG" "$1" <<'PY' 2>/dev/null || true
import sys, tomllib
with open(sys.argv[1], "rb") as f: d = tomllib.load(f)
w = d.get("workspaces", {}).get(sys.argv[2], {})
for a in sorted(w.get("apps", []), key=lambda x: x.get("column", 99)):
    print("|".join(str(a.get(k, "")) for k in ("app_id", "cmd", "width", "height")))
PY
}

_scene_services() {  # $1=ws -> one systemd --user unit name per line (column order N/A)
    python3 - "$SCENE_REG" "$1" <<'PY' 2>/dev/null || true
import sys, tomllib
with open(sys.argv[1], "rb") as f: d = tomllib.load(f)
for s in d.get("workspaces", {}).get(sys.argv[2], {}).get("services", []):
    print(s)
PY
}

_ws_id()     { niri msg --json workspaces | jq -r --arg n "$1" 'first(.[]|select(.name==$n))|.id // empty'; }
_win_id()    { niri msg --json windows    | jq -r --arg a "$1" 'first(.[]|select(.app_id==$a))|.id // empty'; }
_win_on_ws() { niri msg --json windows    | jq -e --arg a "$1" --argjson w "$2" 'any(.[]; .app_id==$a and .workspace_id==$w)' >/dev/null 2>&1; }

# realize_scene <workspace-name>: bring the declared scene into being, idempotently.
realize_scene() {
    local ws="$1"

    # Start the workspace's backing services first — idempotent, and systemd
    # orders any declared deps (e.g. ai-stack Requires=dev-stack-data). This is
    # what makes "arrive at a workspace and its infra is ready" true.
    local svc
    while IFS= read -r svc; do
        [[ -z "$svc" ]] && continue
        if [[ "$SCENE_DRYRUN" == 1 ]]; then
            scene_log "scene[$ws]: would start service $svc"
        else
            # --no-block: never let a slow oneshot (dev-stack-data's ~80s podman
            # compose up) SERIALIZE the login choreography. systemd still orders
            # declared deps; the terminal spawns now and its infra arrives behind it.
            scene_log "scene[$ws]: start service $svc (--no-block)"
            systemctl --user start --no-block "$svc" >/dev/null 2>&1 || true
        fi
    done < <(_scene_services "$ws")

    local delegate; delegate="$(_scene_field "$ws" delegate)"
    if [[ -n "$delegate" ]]; then
        scene_log "scene[$ws]: delegate → $delegate"
        [[ "$SCENE_DRYRUN" == 1 ]] && return 0
        if command -v "$delegate" >/dev/null 2>&1; then setsid -f "$delegate" >/dev/null 2>&1 || true; fi
        return 0
    fi

    local wsid; wsid="$(_ws_id "$ws")"
    if [[ -z "$wsid" ]]; then scene_log "scene[$ws]: no such niri workspace"; return 1; fi

    local app_id cmd width height id t
    while IFS='|' read -r app_id cmd width height; do
        [[ -z "$app_id" ]] && continue
        if _win_on_ws "$app_id" "$wsid"; then
            scene_log "scene[$ws]: $app_id already present — skip"
            continue
        fi
        if [[ "$SCENE_DRYRUN" == 1 ]]; then
            scene_log "scene[$ws]: would spawn $app_id  width=${width:-auto}  → $cmd"
            continue
        fi
        # Strip ZELLIJ* so cockpit terminals (ghostty -e zj <layout>) never think
        # they're nested — otherwise zj's no-nest guard degrades them to a plain
        # shell when a scene is realized from inside a zellij session.
        # Export the workspace's identity hue so the spawned terminal's tools (fzf,
        # nvim) tint their accent to it — the whole stack breathes the workspace.
        scene_log "scene[$ws]: spawn $app_id → $cmd"
        # NOTE: env's -u flags MUST precede any NAME=VALUE assignment. GNU env treats
        # everything after the first assignment as the command, so putting SL_IDENTITY=
        # first made env try to RUN "-u" ("env: '-u': No such file or directory") and
        # NOTHING spawned — the silent bug (since Track 8 / 88620a3) that broke every
        # scene's app staging at login. Order is load-bearing: -u … first, assignment last.
        setsid -f env -u ZELLIJ -u ZELLIJ_SESSION_NAME -u ZELLIJ_PANE_ID SL_IDENTITY="$(sl-identity "$ws")" sh -c "$cmd" >/dev/null 2>&1 || true
        # Wait up to ~25s (100 × 0.25s) for the window to register. This MUST exceed
        # ff-scene's REGISTER_TIMEOUT (20s) — a cold dedicated-profile Firefox (research-web,
        # coding-web) needs more than the old 10s, and giving up early is what triggered the
        # endless "did not register" → reconcile → respawn loop that never converged.
        id=""; t=0
        while [[ -z "$id" && $t -lt 100 ]]; do id="$(_win_id "$app_id")"; [[ -n "$id" ]] && break; sleep 0.25; t=$((t + 1)); done
        if [[ -z "$id" ]]; then scene_log "scene[$ws]: $app_id did not register"; continue; fi
        # Backstop only: niri's open-on-workspace rule already placed AND sized this
        # window at map time. This --focus false move is a no-op when the rule fired,
        # and corrects placement if it ever misfires. No focus-steal, no set-column-
        # width (widths are declarative via each rule's default-column-width). The
        # width/height fields in workspaces.toml are the documented intent those
        # niri rules mirror.
        niri msg action move-window-to-workspace --window-id "$id" --focus false "$ws" >/dev/null 2>&1 || true
        scene_log "scene[$ws]: placed $app_id (id=$id)"
    done < <(_scene_apps "$ws")

    # Ambient focus-music. A workspace may declare `ambient = "<station>"` (lofi/jazz/…)
    # in workspaces.toml; once the scene is up we start low-key radio (mpd via `music
    # radio`, which also brings up mpd-mpris so the Cockpit media HUD lights up). We only
    # ever FILL SILENCE: if anything is already Playing — Spotify on the media ws, or the
    # lofi you left running while hopping coding↔research — we leave it alone. The media
    # workspace deliberately declares no ambient (it's the active-listening space).
    local ambient; ambient="$(_scene_field "$ws" ambient)"
    if [[ -n "$ambient" ]]; then
        if [[ "$SCENE_DRYRUN" == 1 ]]; then
            scene_log "scene[$ws]: would start ambient → music radio $ambient (only if nothing is playing)"
        elif playerctl -a status 2>/dev/null | grep -q Playing; then
            scene_log "scene[$ws]: ambient skip ($ambient) — something is already playing"
        else
            scene_log "scene[$ws]: ambient → music radio $ambient"
            setsid -f music radio "$ambient" >/dev/null 2>&1 || true
        fi
    fi
}
