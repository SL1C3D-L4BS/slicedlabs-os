#!/usr/bin/env bash
# SlicedLabs · tools · © 2026 SlicedLabs
# verify-cockpit.sh — invariants for the Quickshell Cockpit (supersedes the
# Waybar checks in verify-gaming.sh). Static + live (needs the cockpit running).
set -u
pass=0; fail=0
ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass+1)); }
no() { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail+1)); }
chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else no "$1"; fi; }

# Cockpit pills live on the PRIMARY output (DP-2). CenterPill+RightPill also mirror to
# the DP-3 monitoring panel BY DESIGN (shell.qml secondary output), so assert the
# primary's full 3-pill cluster rather than a global count (which is 5 with DP-3 up).
primary_pills() { niri msg --json layers 2>/dev/null | grep -oF '"namespace":"cockpit","output":"DP-2"' | wc -l; }

# shellcheck disable=SC2034  # QS/NIRI are referenced inside the eval'd chk '…' command strings below
QS=~/.config/quickshell/cockpit
# shellcheck disable=SC2034
NIRI=~/.config/niri/config.kdl

echo "── Cockpit · install + service ──"
chk "quickshell installed (qs)"                 'command -v qs'
chk "cava installed (Reactor FFT)"              'command -v cava'
chk "quickshell.service active"                 'systemctl --user is-active --quiet quickshell.service'
chk "quickshell.service no crash-loop"          '[ "$(systemctl --user show -p NRestarts --value quickshell.service)" -lt 3 ]'
chk "waybar.service retired (inactive)"         '! systemctl --user is-active --quiet waybar.service'
chk "waybard retired"                           '! systemctl --user is-active --quiet waybard.service'
chk "waybar-tab-watcher retired"                '! systemctl --user is-active --quiet waybar-tab-watcher.service'

echo "── Cockpit · generated + shaders (SSOT cascade) ──"
chk "shell.qml present (symlink → dotfiles)"    '[ -L "$QS" ] || [ -f "$QS/shell.qml" ]'
chk "generated/Theme.qml exists"                '[ -f "$QS/generated/Theme.qml" ]'
chk "Theme.qml has no unresolved {{tokens}}"    '! grep -q "{{" "$QS/generated/Theme.qml"'
chk "Theme.qml brand() map present"             'grep -q "function brand" "$QS/generated/Theme.qml"'
chk "reactor.frag.qsb compiled"                 '[ -f "$QS/core/shaders/reactor.frag.qsb" ]'
chk "render-quickshell executable"              'command -v render-quickshell'
chk "build-shaders executable"                  'command -v build-shaders'
chk "cockpitctl executable"                     'command -v cockpitctl'

echo "── Cockpit · niri integration ──"
chk "niri config valid"                         'niri validate -c "$NIRI"'
chk "layer-rule namespace=^cockpit\$"           'grep -q "namespace=\"\\^cockpit\\$\"" "$NIRI"'
chk "layer-rule cockpit-modal (screencast block)" 'grep -q "namespace=\"cockpit-modal\"" "$NIRI"'
chk "cockpit IPC binds (>=6)"                   '[ "$(grep -cE "cockpitctl (system|market|hermes|inspect)" "$NIRI")" -ge 6 ]'
chk "theme toggle bind"                         'grep -q "cockpitctl theme" "$NIRI"'

echo "── Cockpit · data reuse ──"
chk "waybar scripts/ preserved (reused)"        '[ -d ~/.config/quickshell/cockpit/scripts ]'
chk "glyphs.sh present (script glyphs)"         '[ -f ~/.config/quickshell/cockpit/scripts/lib/glyphs.sh ]'
chk "active-tab state file writable"            'touch "${XDG_CACHE_HOME:-$HOME/.cache}/cockpit-active-tab"'

echo "── Cockpit · Bluetooth (native picker) ──"
chk "Bt service registered (qmldir)"            'grep -q "singleton Bt 1.0 Bt.qml" "$QS/services/qmldir"'
chk "Bt.qml present"                            '[ -f "$QS/services/Bt.qml" ]'
chk "Bt wraps Quickshell.Bluetooth"             'grep -q "import Quickshell.Bluetooth" "$QS/services/Bt.qml"'
chk "Theme gBluetooth glyphs baked"             'grep -q "gBluetoothConnected" "$QS/generated/Theme.qml"'
chk "RightPill BT status glyph wired"           'grep -q "Bt\." "$QS/bars/RightPill.qml"'
chk "bt device-picker (System card Bluetooth tab)" 'grep -q "Bt.sorted" "$QS/components/SystemCard.qml"'
chk "Mod+Alt+B → System Bluetooth bound"        'grep -q "cockpitctl system bluetooth" "$NIRI"'

echo "── Cockpit · live runtime ──"
chk "3 cockpit pills on primary (DP-2)"         '[ "$(primary_pills)" -eq 3 ]'
chk "IPC reachable (status)"                    'qs -c cockpit ipc call cockpit status'
chk "qs process running"                        'pgrep -f "qs -c cockpit"'

echo "── Cockpit · Liquid Glass + identity pager (2026 redesign) ──"
chk "glass.frag.qsb compiled"                   '[ -f "$QS/core/shaders/glass.frag.qsb" ]'
chk "contrast_floor token baked"                'grep -q "glassContrastFloor" "$QS/generated/Theme.qml"'
chk "focal Liquid Glass tokens baked"           'grep -q "glassFocalSpecularSpeed" "$QS/generated/Theme.qml"'
chk "semantic role tier baked"                  'grep -q "semBgPrimary" "$QS/generated/Theme.qml"'
# identity anchor exact — read the canonical hex from color.py ANCHORS (the
# SSOT) so a deliberate re-hue (e.g. Liquid Retina v3) never stales this gate.
ENGINE_HEX="$(python3 -c "import sys; sys.path.insert(0, \"$HOME/.dotfiles/bin/.local/bin/lib\"); import color; print(color.ANCHORS[\"engine\"])")"
chk "identity anchor exact (engine=$ENGINE_HEX)" 'grep -qE "engine: .$ENGINE_HEX" "$QS/generated/Theme.qml"'
chk "OKLCH round-trip (color.py --selftest)"    'python3 ~/.dotfiles/bin/.local/bin/lib/color.py --selftest'
chk "pager: official identity glyphs"           'grep -q "Theme.glyph" "$QS/bars/LeftPill.qml" && grep -q "wsOrder" "$QS/bars/LeftPill.qml"'
chk "pager: active accent border"               'grep -q "pagerActiveBorder" "$QS/bars/LeftPill.qml"'
chk "workspace remap clean (guarantee #1)"      'verify-workspace-remap'
chk "design language: no raw hex (guarantee #6)" 'verify-design-language'

echo
printf 'Cockpit: \033[32m%d pass\033[0m / \033[31m%d fail\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
