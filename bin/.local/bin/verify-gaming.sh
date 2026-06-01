#!/usr/bin/env bash
# verify-gaming.sh — Phase 12 end-to-end checks for the gaming stack.
#
# Every check prints PASS/FAIL with a one-line reason. A summary at the end
# tallies failures. Exits non-zero if anything fails, so this can also be
# wired into CI later.

set -u

PASS=0
FAIL=0
WARN=0

g() { printf '\033[32m%s\033[0m' "$*"; }
r() { printf '\033[31m%s\033[0m' "$*"; }
y() { printf '\033[33m%s\033[0m' "$*"; }
b() { printf '\033[1m%s\033[0m'   "$*"; }

ok()    { printf '  %s %s\n' "$(g 'PASS')" "$1"; PASS=$((PASS+1)); }
fail()  { printf '  %s %s\n' "$(r 'FAIL')" "$1"; FAIL=$((FAIL+1)); }
warn()  { printf '  %s %s\n' "$(y 'WARN')" "$1"; WARN=$((WARN+1)); }
sect()  { printf '\n%s\n' "$(b "$1")"; }

# ---------- 1. Kernel/user limits ----------
sect "Kernel + user limits"

if id -nG | grep -qw input;    then ok "user in input group";    else fail "missing 'input' group — re-login needed"; fi
if id -nG | grep -qw gamemode; then ok "user in gamemode group"; else fail "missing 'gamemode' group — re-login needed"; fi

rt=$(prlimit --rtprio --output=SOFT --noheadings 2>/dev/null | tr -d ' ')
if [[ "$rt" == "20" ]]; then ok "rtprio soft-limit = 20"; else fail "rtprio = ${rt:-?} (expected 20 from limits.d/99-gaming.conf — re-login?)"; fi

nof=$(prlimit --nofile --output=SOFT --noheadings 2>/dev/null | tr -d ' ')
if (( nof >= 524288 )); then ok "nofile soft-limit ≥ 524288 ($nof)"; else fail "nofile = ${nof:-?} (expected ≥ 524288)"; fi

# ---------- 2. Kernel modules ----------
sect "Kernel modules"

if lsmod | grep -q '^hid_playstation'; then ok "hid_playstation loaded"; else fail "hid_playstation not loaded"; fi
if lsmod | grep -q '^hidp';            then ok "hidp loaded (BT HID profile)"; else fail "hidp not loaded — DS4 BT will pair but HID won't bind"; fi
if lsmod | grep -q '^amdgpu';          then ok "amdgpu loaded";          else fail "amdgpu not loaded"; fi
if grep -q '^MODULES=(amdgpu' /etc/mkinitcpio.conf; then ok "amdgpu in initramfs MODULES (early KMS)"; else fail "amdgpu not in /etc/mkinitcpio.conf MODULES"; fi
grep -q '^hid_playstation$' /etc/modules-load.d/playstation.conf 2>/dev/null \
    && ok "hid_playstation autoload configured" \
    || fail "missing hid_playstation in /etc/modules-load.d/playstation.conf"
grep -q '^hidp$' /etc/modules-load.d/playstation.conf 2>/dev/null \
    && ok "hidp autoload configured" \
    || fail "missing hidp in /etc/modules-load.d/playstation.conf (DS4 BT bonding workaround)"

# ---------- 3. Pacman + packages ----------
sect "Packages"

if grep -q '^\[multilib\]' /etc/pacman.conf; then ok "multilib repo enabled"; else fail "multilib not enabled in /etc/pacman.conf"; fi

OFFICIAL=(steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope lutris goverlay amdgpu_top corectrl mesa-utils vulkan-tools lib32-vulkan-radeon ydotool)
AUR=(heroic-games-launcher-bin protonup-rs bottles vkbasalt lib32-vkbasalt)

missing=()
for p in "${OFFICIAL[@]}" "${AUR[@]}"; do
    pacman -Q "$p" &>/dev/null || missing+=("$p")
done
if (( ${#missing[@]} == 0 )); then
    ok "all ${#OFFICIAL[@]} official + ${#AUR[@]} AUR packages installed"
else
    fail "missing packages: ${missing[*]}"
fi

# ---------- 4. Config files ----------
sect "Config files"

for f in \
    /etc/security/limits.d/99-gaming.conf \
    /etc/modules-load.d/playstation.conf \
    /etc/gamemode.ini \
    "$HOME/.config/MangoHud/MangoHud.conf" \
    "$HOME/.config/wireplumber/wireplumber.conf.d/53-gaming.conf"
do
    [[ -f "$f" ]] && ok "$(basename "$f") present" || fail "$f missing"
done

# ---------- 5. Waybar gaming tab ----------
sect "Waybar gaming tab"

state_file="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-active-tab"
prev_state=$(cat "$state_file" 2>/dev/null || echo "")
echo gaming > "$state_file"

scripts=(cpu_temp gpu gamemode ds4 status mangohud_toggle launcher)
for s in "${scripts[@]}"; do
    out=$("$HOME/.config/waybar/scripts/gaming/$s.sh" 2>/dev/null)
    if [[ -n "$out" ]] && printf '%s' "$out" | jq -e . &>/dev/null; then
        ok "$s.sh emits valid JSON"
    else
        fail "$s.sh did not emit JSON"
    fi
done
[[ -n "$prev_state" ]] && echo "$prev_state" > "$state_file"

# mangohud-toggle + quick-launcher were intentionally moved off the bar into the
# Mod+Shift+G fuzzel action menu, so they are no longer bar chips.
for mod in custom/gaming-status custom/gpu-stats custom/cpu-temp custom/gamemode custom/ds4-battery; do
    grep -q "\"$mod\"" "$HOME/.config/waybar/config.jsonc" \
        && ok "Waybar wires $mod" \
        || fail "Waybar missing $mod"
done

# ---------- 5b. Tab system ----------
sect "Tab system (workspace-driven)"

grep -q '"output": "HDMI-A-1"' "$HOME/.config/waybar/config.jsonc" \
    && ok "Waybar pinned to HDMI-A-1 only" \
    || fail "Waybar not pinned to HDMI-A-1 (would also render on 24\" portrait)"

[[ -x "$HOME/.local/bin/waybar-tab-watcher" ]] \
    && ok "waybar-tab-watcher exists + executable" \
    || fail "missing $HOME/.local/bin/waybar-tab-watcher"

systemctl --user is-active quickshell.service &>/dev/null \
    && ok "quickshell.service active (Cockpit — supersedes waybar-tab-watcher)" \
    || fail "quickshell.service not active (systemctl --user start it)"

if [[ -f "$HOME/.cache/waybar-active-tab" ]]; then
    cur_tab=$(<"$HOME/.cache/waybar-active-tab")
    case "$cur_tab" in
        coding|research|engine|browser|monitoring|streaming|gaming|media|net|ai|agenda)
            ok "active-tab cache populated: $cur_tab"
            ;;
        *)
            fail "active-tab cache has unknown value: $cur_tab"
            ;;
    esac
else
    fail "$HOME/.cache/waybar-active-tab missing"
fi

for tab_script in \
    "$HOME/.config/waybar/scripts/tabs/header.sh" \
    "$HOME/.config/waybar/scripts/engine/target.sh" \
    "$HOME/.config/waybar/scripts/engine/tests.sh" \
    "$HOME/.config/waybar/scripts/comms/discord.sh" \
    "$HOME/.config/waybar/scripts/comms/notifs.sh" \
    "$HOME/.config/waybar/scripts/comms/mail.sh" \
    "$HOME/.config/waybar/scripts/stream/obs.sh" \
    "$HOME/.config/waybar/scripts/stream/mic.sh" \
    "$HOME/.config/waybar/scripts/stream/uptime.sh" \
    "$HOME/.config/waybar/scripts/monitoring/top-cpu.sh" \
    "$HOME/.config/waybar/scripts/monitoring/top-mem.sh" \
    "$HOME/.config/waybar/scripts/monitoring/failed-units.sh" \
    "$HOME/.config/waybar/scripts/monitoring/net-io.sh"
do
    [[ -x "$tab_script" ]] || fail "missing or not executable: $tab_script"
done
# silent ok if all 13 are good — they're tested individually elsewhere
all_ok=true
for s in tabs/header engine/target engine/tests comms/discord comms/notifs comms/mail \
         stream/obs stream/mic stream/uptime monitoring/top-cpu monitoring/top-mem \
         monitoring/failed-units monitoring/net-io; do
    [[ -x "$HOME/.config/waybar/scripts/$s.sh" ]] || all_ok=false
done
$all_ok && ok "all 13 tab-module scripts present + executable"

[[ -x "$HOME/.local/bin/obs-ws-query" ]] \
    && ok "obs-ws-query helper installed" \
    || warn "obs-ws-query missing — stream-obs chip falls back to presence-only"

# ---------- 6. Niri keybinds ----------
sect "Niri keybinds"

NIRI=$HOME/.dotfiles/niri/.config/niri/config.kdl
grep -qE '^workspace "gaming"'                                       "$NIRI" && ok "gaming workspace defined"   || fail "gaming workspace block missing in niri config"
grep -qE '^[[:space:]]*Mod\+7[[:space:]]+\{[[:space:]]*focus-workspace[[:space:]]+"gaming"' "$NIRI" && ok "Mod+7 → gaming workspace" || fail "Mod+7 binding missing or wrong target"
grep -qE '^[[:space:]]*Mod\+Shift\+7[[:space:]]+\{[[:space:]]*move-column-to-workspace[[:space:]]+"gaming"' "$NIRI" && ok "Mod+Shift+7 → move to gaming" || fail "Mod+Shift+7 binding missing"
grep -qE '^[[:space:]]*Mod\+Shift\+G[[:space:]]+\{[[:space:]]*spawn' "$NIRI" && ok "Mod+Shift+G keybind"  || fail "Mod+Shift+G keybind missing"
grep -qE '^[[:space:]]*Mod\+Ctrl\+G[[:space:]]+\{[[:space:]]*spawn'  "$NIRI" && ok "Mod+Ctrl+G keybind"   || fail "Mod+Ctrl+G keybind missing"
# Mod+G is now the context-sensitive gaming action (workspace-gaming-action);
# the old MangoHud-toggle meaning was retired when the tab system landed.
if grep -qE '^[[:space:]]*Mod\+G[[:space:]]+\{[[:space:]]*spawn.*workspace-gaming-action' "$NIRI"; then
    ok "Mod+G → workspace-gaming-action (context-sensitive)"
else
    fail "Mod+G not bound to workspace-gaming-action"
fi

if niri validate 2>/dev/null; then
    ok "niri validate passes"
else
    warn "niri validate failed (or niri not on PATH)"
fi

# ---------- 7. Services + daemons ----------
sect "Services"

systemctl --user is-active ydotool &>/dev/null  && ok "ydotoold running"        || fail "ydotoold not active"
[[ -S /run/user/$(id -u)/.ydotool_socket ]]     && ok "ydotool socket present"  || fail "ydotool socket missing"

systemctl is-active bluetooth.service &>/dev/null && ok "bluetooth.service running" || warn "bluetooth.service not running (only needed for BT pads)"

grep -qE '^ClassicBondedOnly=false' /etc/bluetooth/input.conf \
    && ok "BlueZ ClassicBondedOnly=false (DS4 over BT bonds correctly)" \
    || fail "BlueZ ClassicBondedOnly still default true — DS4 over BT will pair but not bind HID"

if gamemoded -s 2>&1 | grep -q 'inactive\|active'; then
    ok "gamemoded responds to status query"
else
    fail "gamemoded not responding"
fi

# ---------- 8. OBS gaming scenes ----------
sect "OBS gaming scenes"

OBS_JSON=$HOME/.config/obs-studio/basic/scenes/Engine.json
if [[ -f "$OBS_JSON" ]]; then
    if jq -e '.sources[] | select(.name == "Gaming — TV")' "$OBS_JSON" >/dev/null; then
        ok "scene 'Gaming — TV' present"
    else
        fail "scene 'Gaming — TV' missing"
    fi
    if jq -e '.sources[] | select(.name == "Gaming — Window")' "$OBS_JSON" >/dev/null; then
        ok "scene 'Gaming — Window' present"
    else
        fail "scene 'Gaming — Window' missing"
    fi
    if jq -e '.sources[] | select(.id == "pipewire-window-capture-source")' "$OBS_JSON" >/dev/null; then
        ok "pipewire-window-capture source present"
    else
        fail "pipewire-window-capture source missing"
    fi
else
    warn "OBS Engine.json not found — OBS scenes can't be verified"
fi

# ---------- 9. Snapper safety net ----------
sect "Snapper rollback"

if snapper -c root list 2>/dev/null | grep -q 'pre-gaming'; then
    ok "pre-gaming snapper snapshot exists"
elif snapper -c root list 2>/dev/null | grep -q '^[0-9]'; then
    warn "no 'pre-gaming' snapshot label — pre-install snapshot may be unlabeled"
else
    warn "snapper not configured for root"
fi

# ---------- 10. Optional: live state (controller, GameMode active) ----------
sect "Live state (informational)"

if compgen -G '/sys/class/power_supply/ps-controller-battery-*' >/dev/null; then
    for bat in /sys/class/power_supply/ps-controller-battery-*; do
        printf '  %s DS4 paired: %s%% (%s)\n' "$(g 'INFO')" "$(<"$bat/capacity")" "$(<"$bat/status")"
    done
else
    printf '  %s no DS4 controller currently paired (USB plug or BT)\n' "$(y 'INFO')"
fi

if gamemoded -s 2>&1 | grep -q 'is active'; then
    printf '  %s GameMode currently ACTIVE\n' "$(g 'INFO')"
else
    printf '  %s GameMode currently idle\n' "$(y 'INFO')"
fi

if [[ -f /var/lib/snapper/configs/root ]]; then
    last=$(snapper -c root list 2>/dev/null | tail -1 | awk -F'│' '{print $2$3}' | tr -d ' ')
    [[ -n "$last" ]] && printf '  %s latest snapper snapshot: %s\n' "$(g 'INFO')" "$last"
fi

# ---------- Waybar redesign (fused tabs · HUD overlays · daemon · theme) ----------
sect "Waybar redesign"

WB="$HOME/.config/waybar"
TM="$WB/style.css.tmpl"; CT="$WB/config.jsonc.tmpl"

python3 - <<'PY' 2>/dev/null && ok "tabs.toml parses · 11 tabs (7 ws + 4 overlay)" || fail "tabs.toml invalid or wrong tab count"
import tomllib, sys, pathlib
r = tomllib.loads(pathlib.Path.home().joinpath(".config/waybar/tabs.toml").read_text())
o = r["meta"]["order"]
ws = [t for t in o if r["tabs"][t]["kind"] == "workspace"]
ov = [t for t in o if r["tabs"][t]["kind"] == "overlay"]
sys.exit(0 if len(o) == 11 and len(ws) == 7 and len(ov) == 4 else 1)
PY

[[ -f "$WB/scripts/lib/tabs.env" ]] && ok "tabs.env generated" || fail "tabs.env missing (run render-waybar)"
[[ -f "$WB/scripts/lib/glyphs.sh" ]] && grep -q '^G_OK=' "$WB/scripts/lib/glyphs.sh" && ok "glyphs.sh rendered from [icon]" || fail "glyphs.sh missing/unrendered"

for m in center tab-modules; do grep -q "GENERATED:$m" "$CT" && ok "config marker GENERATED:$m" || fail "config missing GENERATED:$m"; done
for m in base-selectors header-selectors module-padding lift fusion; do grep -q "GENERATED:$m" "$TM" && ok "css marker GENERATED:$m" || fail "css missing GENERATED:$m"; done

u=$(grep -c '{{' "$WB/config.jsonc" "$WB/style.css" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
(( u == 0 )) && ok "rendered config/style: no unresolved {{tokens}}" || fail "$u unresolved tokens — run render-waybar && render-templates"

python3 - <<'PY' 2>/dev/null && ok "clock in right cluster (centre freed for the active tab)" || fail "clock not relocated to modules-right"
import re, json, sys, pathlib
t = pathlib.Path.home().joinpath(".config/waybar/config.jsonc").read_text()
t = re.sub(r'/\*.*?\*/', '', t, flags=re.S); t = re.sub(r'//[^\n]*', '', t); t = re.sub(r',(\s*[\]}])', r'\1', t)
d = json.loads(t)
sys.exit(0 if "clock" in d["modules-right"] and "clock" not in d["modules-center"] else 1)
PY

for kf in pulse-build pulse-rec pulse-live glow-urgent tab-in; do
    grep -q "@keyframes $kf" "$WB/style.css" && ok "keyframe $kf present" || fail "keyframe $kf missing"
done

caps=$(grep -cE '#custom-tab-[a-z]+-header \{ background:' "$WB/style.css")
(( caps == 11 )) && ok "11 brand-cap fusion rules" || fail "expected 11 cap rules, found $caps"
urg=$(grep -cE '#custom-tab-[a-z]+-header\.urgent' "$WB/style.css")
(( urg == 11 )) && ok "11 cap urgent-glow rules" || fail "expected 11 urgent rules, found $urg"

for t in media net ai agenda; do grep -q "custom/tab-$t-header" "$WB/config.jsonc" && ok "HUD tab '$t' wired into config" || fail "HUD tab '$t' missing from config"; done

miss=0
for s in media/now.sh media/easyeffects.sh media/sink.sh net/vpn.sh net/firewall.sh net/route.sh net/link.sh ai/spend.sh ai/agents.sh ai/pomo.sh agenda/next.sh agenda/standup.sh alerts.sh; do
    [[ -x "$WB/scripts/$s" ]] || miss=$((miss+1))
done
(( miss == 0 )) && ok "13 new module scripts present + executable" || fail "$miss new module scripts missing/non-exec"

ss=0
for s in scene bitrate uptime; do grep -q '"class":"empty"' "$WB/scripts/stream/$s.sh" && ss=$((ss+1)); done
(( ss == 3 )) && ok "stream scripts emit placeholders when OBS down (stable fusion)" || fail "stream placeholder fix incomplete ($ss/3)"

for f in waybard waybar-hud standup-post; do [[ -x "$HOME/.local/bin/$f" ]] && ok "$f present + executable" || fail "$HOME/.local/bin/$f missing/non-exec"; done
systemctl --user is-active --quiet quickshell.service && ok "quickshell.service active (Cockpit)" || fail "quickshell.service not active"
command -v verify-cockpit.sh >/dev/null && ok "verify-cockpit.sh present (run it for the Cockpit HUD)" || warn "verify-cockpit.sh missing"

th=$(cat "$HOME/.cache/waybar-theme" 2>/dev/null || echo "")
[[ "$th" == dark || "$th" == light ]] && ok "theme state valid ($th)" || warn "theme state unset (defaults dark)"
hb=$(grep -c 'cockpitctl' "$HOME/.config/niri/config.kdl" 2>/dev/null)
(( hb >= 6 )) && ok "niri cockpit binds present ($hb)" || fail "niri cockpitctl binds missing ($hb<6)"

pgrep -f 'qs -c cockpit' >/dev/null && ok "cockpit (qs) process alive" || fail "cockpit not running"

# ---------- Full-stack: engine cascade · slicedlabs · containers · design ----------
sect "Full-stack: engine + slicedlabs + design system"

for t in render-waybar render-engine-palette waybar-hud waybard ai-stack-up dev-stack-up; do
    command -v "$t" >/dev/null 2>&1 && ok "$t on PATH" || fail "$t not on PATH (stow bin?)"
done

PAL="$HOME/Projects/engine/crates/engine-ui/src/theme/palette.rs"
[[ -f "$PAL" ]] && grep -q 'PRIMARY' "$PAL" && ok "engine palette.rs generated (tokens → Rust)" || fail "engine palette.rs missing/empty"
if [[ -d "$HOME/Projects/engine" ]] && command -v cargo >/dev/null 2>&1; then
    ( cd "$HOME/Projects/engine" && cargo build -q -p engine-ui -p engine-editor >/dev/null 2>&1 ) \
        && ok "engine-ui + engine-editor build green" || fail "engine crates fail to build"
fi

slicedlabs cost today --format json 2>/dev/null | jq -e '.total!=null and .soft_cap!=null and .active!=null' >/dev/null 2>&1 \
    && ok "slicedlabs cost --format json valid" || fail "slicedlabs cost --format json broken"
slicedlabs agents --format json 2>/dev/null | jq -e '.active!=null' >/dev/null 2>&1 \
    && ok "slicedlabs agents --format json valid" || fail "slicedlabs agents missing/broken"

up=$(podman ps -q 2>/dev/null | wc -l)
(( up >= 13 )) && ok "container stack: $up up (≥13)" || warn "container stack: $up up — run dev-stack-up && ai-stack-up --profile memory --profile kg"
# dev/ai-stack are STAGED ON-DEMAND by workspace scenes (workspaces.toml services=…),
# per the lean-boot contract — NOT auto-started. So assert the units are installed and
# loadable (scenes can stage them), never that they're 'enabled' for boot.
systemctl --user cat dev-stack.service ai-stack.service >/dev/null 2>&1 \
    && ok "dev/ai-stack units installed (on-demand, staged by scenes)" \
    || fail "dev/ai-stack units missing — scenes can't stage them"

draw=$(cd "$HOME/.dotfiles" && for f in $(find . -name '*.tmpl' ! -path '*brand-assets*' ! -path '*wallpaper*'); do sed 's/{{[^}]*}}//g' "$f" | grep -oiE '#[0-9a-f]{6}\b'; done | wc -l)
(( draw == 0 )) && ok "templates: 0 raw #hex (token-pure)" || fail "$draw raw #hex literals in templates"
# (starship retired in favour of tide — its old glyph check is gone; the token-pure
# gate above already guarantees the tide/zjstatus/lualine templates carry no raw values.)

# ---------- 2026 build-out: bar centering · scenes · palette · TUI · media ----------
sect "2026 build-out: bar · scenes · palette · cockpit · media"

WB_CSS="$HOME/.config/waybar/style.css"
SLT="$HOME/.dotfiles/slicedlabs-team/slicedlabs_team"
# Center-visibility guard (2026-05-29 regression): modules-center is a GTK
# center-widget whose usable width is (bar − 2×left), so a big min-width on the
# left cluster clips every tab cluster to invisibility. Assert it stays absent.
grep -Eq 'min-width: *[0-9]{3,}px' "$WB_CSS" 2>/dev/null \
    && fail "oversized min-width in waybar CSS — clips the centered tab cluster (the 2026-05-29 regression)" \
    || ok "no oversized min-width (center cluster not reserve-clipped)"
# Cap centring lead is a MARGIN (counterweights data chips to centre the brand
# word); it must NOT be a min-width (that would clip — see guard above).
grep -Eq '#custom-tab-engine-header \{.*margin: [0-9]+px 0 [0-9]+px [0-9]+px' "$WB_CSS" 2>/dev/null \
    && ok "engine cap has a left-margin centring lead (not a min-width)" || fail "engine cap margin missing/malformed"
grep -Eq '^[[:space:]]*(left_reserve|bar_center)[[:space:]]*=' "$HOME/.dotfiles/system/tokens.toml" \
    && fail "left_reserve/bar_center reintroduced in tokens — they clip the center" \
    || ok "tokens: cap-centering tokens retired (no left_reserve/bar_center assignment)"

REG="$HOME/.config/sliced-engine/workspaces.toml"
python3 -c "import tomllib,sys; sys.exit(0 if tomllib.load(open('$REG','rb')).get('meta',{}).get('auto') else 1)" 2>/dev/null \
    && ok "workspaces.toml parses with [meta].auto" || fail "workspaces.toml missing/invalid"
[[ -f "$HOME/.local/bin/lib/scene.sh" ]] && ok "lib/scene.sh linked" || fail "lib/scene.sh missing"
for t in cockpit sliced-menu dev-stack-down ai-stack-down manim-render; do
    command -v "$t" >/dev/null 2>&1 && ok "$t on PATH" || fail "$t not on PATH (stow bin?)"
done
cockpit --list >/dev/null 2>&1 && ok "cockpit --list works" || fail "cockpit --list errors"
grep -q 'Mod+Alt+Space' "$HOME/.config/niri/config.kdl" 2>/dev/null \
    && ok "command palette keybind (Mod+Alt+Space) present" || fail "palette keybind missing"
command -v music >/dev/null 2>&1 && systemctl --user is-active mpd.service >/dev/null 2>&1 \
    && ok "music: mpd active + music cmd on PATH" || warn "music stack not fully up (mpd/music)"
{ [ -f "$HOME/.config/quickshell/cockpit/generated/Theme.qml" ] && ! grep -q '{{' "$HOME/.config/quickshell/cockpit/generated/Theme.qml"; } \
    && ok "token SSOT: cockpit Theme.qml in sync (no unresolved tokens)" || fail "cockpit Theme.qml drift — run render-quickshell"
systemctl is-active vector >/dev/null 2>&1 \
    && ok "observability: vector shipping journald -> Loki" || warn "vector not active (Loki log shipping)"
systemctl is-active tetragon >/dev/null 2>&1 \
    && ok "runtime security: Cilium Tetragon active (eBPF)" || warn "tetragon not active"
{ systemctl is-enabled nftables >/dev/null 2>&1 && ! systemctl is-enabled ufw >/dev/null 2>&1; } \
    && ok "firewall: nftables enabled, ufw disabled (no dual-stack)" || warn "firewall: check nftables/ufw state"

grep -q 'id="control"' "$SLT/tui.py" 2>/dev/null \
    && ok "slicedlabs TUI Control tab present" || fail "TUI Control tab missing"
grep -q 'invoke_without_command=True' "$SLT/cli.py" 2>/dev/null \
    && ok "bare slicedlabs → inline TUI (cli callback)" || fail "inline-TUI callback missing"
grep -q 'def enforce' "$SLT/hooks/cost_cap.py" 2>/dev/null && grep -q 'enforce(' "$SLT/cli.py" 2>/dev/null \
    && ok "cost-cap enforce() defined + wired into cli" || fail "cost-cap enforcement not wired"

for t in manim typst vhs asciinema d2; do
    command -v "$t" >/dev/null 2>&1 && ok "$t installed" || fail "$t missing"
done
PATH="$HOME/.bun/bin:$PATH" command -v mmdc >/dev/null 2>&1 && ok "mermaid (mmdc) installed" || warn "mmdc not on PATH (bun global)"
[[ -f "$HOME/.dotfiles/fish/.config/fish/functions/sl.fish" ]] && ok "sl alias (fish function) present" || warn "sl alias missing"

# ---------- Summary ----------
sect "Summary"
printf '  %s passed, %s failed, %s warnings\n' "$(g "$PASS")" "$(r "$FAIL")" "$(y "$WARN")"
(( FAIL == 0 )) && {
    printf '\n%s All %s checks green.\n' "$(g '✓')" "$PASS"

    # Stateful "still pending" list — only show phases whose evidence is missing.
    pending=()
    compgen -G "$HOME/.steam/root/compatibilitytools.d/GE-Proton*" >/dev/null \
        || pending+=("Phase 4  — Steam login + GE-Proton install (run: steam-first-launch.sh)")
    compgen -G '/sys/class/power_supply/ps-controller-battery-*' >/dev/null \
        || pending+=("Phase 9  — Plug DS4 USB or pair via bluetoothctl (run: ds4-pair.sh)")
    pending+=("Phase 12 — Launch a ProtonDB Platinum game (Portal 2 / Hades / Hollow Knight) and confirm: MangoHud bottom-right, Mod+7 shows the gaming tab + chips, GMODE chip flips ON, DS4 input works")

    if (( ${#pending[@]} > 1 )); then
        printf '\n  Still pending:\n'
        for p in "${pending[@]}"; do printf '    %s\n' "$p"; done
    else
        printf '\n  Last touchpoint:\n    %s\n' "${pending[0]}"
    fi
    exit 0
} || {
    printf '\n%s Fix the failures above before declaring the stack ready.\n' "$(r '✗')"
    exit 1
}
