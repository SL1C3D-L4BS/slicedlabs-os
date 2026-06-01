# RUNBOOK: mac-air-sl1c3d

Operational reference for the MacBook Air after the 2026-05-27 rebuild. Quick lookups for "where does X live", "how do I redo Y", and "what's still pending."

## Identity

| Field | Value |
|---|---|
| Hostname | `mac-air-sl1c3d` (ComputerName + LocalHostName) |
| LAN IP   | host-private — tracked in `~/.ssh/config.d/local.conf` (see dotfiles-secret-split). DHCP — pin via router reservation if you want stability. |
| User     | `thearchitect` (uid 501) |
| OS       | macOS 15.7.7 Sequoia, Build 24G720 |
| Hardware | MacBookAir9,1 — Intel i3 1.1 GHz dual-core, 8 GB RAM, 233 GB APFS |
| Login shell | `/usr/local/bin/fish` |
| Brew prefix | `/usr/local` (Intel) |
| Apple ID | **NONE — signed out, no iCloud, no App Store** |

## Security baseline (Tier 1)

| Control | State / Path |
|---|---|
| FileVault | ON (recovery key — capture from System Settings → Privacy & Security if not already saved) |
| SIP | enabled (do not disable) |
| Gatekeeper | assessments enabled |
| Application Firewall (alf) | on + stealth + logging |
| Software updates | auto-check + critical-install on; macOS major upgrades manual |
| DNS | Unbound on 127.0.0.1 → DoT to Quad9 (9.9.9.11 / 149.112.112.11), DNSSEC validating |
| Sudo | `NOPASSWD: ALL` for `thearchitect` via `/etc/sudoers.d/99-thearchitect-nopasswd` (revert: `sudo rm` the file) |

## Tier 2 hardening

| Control | Where |
|---|---|
| pf anchor | `/etc/pf.anchors/sl1c3d.rules` + `anchor "sl1c3d"` in `/etc/pf.conf` (default-deny ingress, allowlist for LAN /24 SSH, ICMP, IPv6 NDP, DHCP). LAN CIDR is host-private; keep redactions in tracked copies. |
| pf backup | `/etc/pf.conf.PRE-SL1C3D-20260527-025654` |
| osquery | `/Library/LaunchDaemons/io.osquery.agent.plist`, config `/var/osquery/osquery.conf` |
| SSH client crypto | shipped via dotfile `ssh/.ssh/config` |
| LuLu (L4 app firewall) | `/Applications/LuLu.app` — **first-launch GUI grant required** |
| BSD audit | **gap** — Sequoia removed it; rely on osquery + Endpoint Security + unified log |

## Tier 3 — pending (see [[macbook-air-pending]] memory for full punch list)

| Item | What you need to do |
|---|---|
| Claude Code auth | run `claude` once at the Mac; OAuth in browser |
| GPG private key | sneakernet from Arch via encrypted USB; `gpg --import`; `pass init <fp>` |
| Discord bot token | **ROTATE FIRST** (leaked 2026-05-21) at Discord dev portal; `pass insert discord/bot-token` |
| Claude MCP register | `claude mcp add discord uv run --quiet ~/discord-mcp/server.py` |
| FIDO2-SK GitHub key | YubiKey at Mac; `ssh-keygen -t ed25519-sk -C mac-air-sl1c3d@SL1C3D-L4BS`; upload pubkey; update `~/.ssh/config.d/local.conf` |
| WireGuard wire-up | Mac pub `DlxUd/+o8PSEaEfuILyzjGbPVtDhmJbfyUPX1j/inQI=` — add to Arch peer config; fill Arch peer pubkey + endpoint into `/usr/local/etc/wireguard/wg0.conf`; `sudo wg-quick up wg0` |
| age recipient | Mac pub `age1jvdy74rnxp0gjwu8weca3l4tvmgsn0frtlz79r5svf4ywsq34pvs50e73k` — add to `.sops.yaml` recipients; rerun `render-secrets` |
| Restic backup | Plug APFS-Encrypted USB; `restic init --repo /Volumes/<usb>/restic-mac-air` |
| Time Machine | enable to second APFS volume |

## Dev environment

```
Engine repo:         ~/Projects/engine  (origin SL1C3D-L4BS/engine, HEAD 1501720)
cargo check:         passes in ~35s with sccache cache
Toolchains (mise):   go, node, ruby, zig
Rust:                1.95.0 (rustup-managed via brew)
Linker override:     ~/.config/fish/conf.d/99-local-mac.fish sets CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=clang
                     (the dotfile cargo config targets osxcross from Arch; this overrides for native Mac builds)
```

## Lima Arch VM (`limactl shell arch`)

```
Image:    Arch-Linux-x86_64-cloudimg-20260401.509747
Kernel:   Linux 6.19.10-arch1-1 x86_64
Profile:  1 vCPU, 2 GB RAM, 100 GB disk
SSH:      127.0.0.1:51371
Mount:    /Users/thearchitect ↔ /Users/thearchitect (engine repo visible from both)
Reset:    limactl factory-reset arch  (rebuilds from template; host mount preserved)
```

Use the VM for: podman, nftables / iptables experiments, Falco / Tetragon / eBPF, AppArmor profiles, anything Linux-native.

## Dotfiles deployment (re-runnable)

```fish
# On Mac, fresh checkout:
git clone git@github.com:SL1C3D-L4BS/env.git ~/.dotfiles
cd ~/.dotfiles
./bin/.local/bin/render-templates
stow --target=$HOME bin cargo direnv fish ghostty mise nvim ssh starship zellij
./bin/.local/bin/install-hooks ~/.dotfiles
```

Host-private overrides (chmod 600, NOT committed):
- `~/.ssh/config.d/local.conf` — points `Host github.com` IdentityFile at the actual Mac key (`id_ed25519_sl1c3d`)
- `~/.config/fish/conf.d/99-local-mac.fish` — `CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=clang`, `SCCACHE_DIR=~/.cache/sccache`

## Firefox

```
Profile:        ~/Library/Application Support/Firefox/Profiles/fcq0bo72.default-release
user.js:        arkenfox (latest from upstream)
user-overrides.js: thin template (network.trr.mode=5 to defer to system Unbound)
Enterprise:     /Applications/Firefox.app/Contents/Resources/distribution/policies.json
  - DisableTelemetry, DisableFirefoxStudies, DisableFirefoxAccounts, DisablePocket
  - Cookies: reject-tracker-and-partition-foreign
  - DNSOverHTTPS: locked off (system uses Unbound)
  - Permissions: Camera/Mic/Location/Notifications all block-new
  - Extensions force-installed: uBlock Origin, Multi-Account Containers
  - DisableAppUpdate (we manage via brew cask if installed that way)
```

## Backups taken during rebuild

| Path | What |
|---|---|
| `~/.config.backup-PRE-DOTFILES-20260527-022358` | Pre-stow `~/.config` (fish, nvim, starship.toml, git, gh, wezterm, etc.) |
| `~/.ssh/config.PRE-DOTFILES-20260527-022358` | Pre-stow `~/.ssh/config` |
| `/etc/pf.conf.PRE-SL1C3D-20260527-025654` | Pre-modification `/etc/pf.conf` |

Safe to delete once the new state is validated.

## Recovery

- **Lost SSH access** (pf rule problem): At the Mac console, `sudo pfctl -d` disables pf. Then fix `/etc/pf.anchors/sl1c3d.rules` and `sudo pfctl -f /etc/pf.conf`.
- **DNS broken** (Unbound down): `sudo networksetup -setdnsservers Wi-Fi empty` restores ISP DNS. `sudo launchctl kickstart -k system/local.unbound` restarts Unbound.
- **FileVault recovery key**: irrecoverable without the key. Without Apple ID, no key escrow — keep a printed copy somewhere safe.
- **fish broken**: `chsh -s /bin/zsh` (zsh is in `/etc/shells` already) from any logged-in shell.
- **Lima VM corrupted**: `limactl factory-reset arch` (host mount preserved).

## Drift checks (run periodically)

```fish
# Weekly
softwareupdate -l            # security patches available?
brew outdated                # formulae/casks
brew update && brew upgrade  # if happy

# Monthly
sudo pfctl -s rules          # firewall ruleset intact
sudo pfctl -a sl1c3d -s rules
dig +dnssec example.com      # Unbound + DNSSEC still working
fdesetup status              # FileVault still on
csrutil status               # SIP still on

# Quarterly
restic check --read-data     # backup integrity
limactl shell arch -- pacman -Syu --noconfirm  # Arch VM updates
```

## Things NOT done deliberately

- Streaming stack (OBS, EasyEffects, Wave XLR) — PipeWire-only, won't translate.
- Niri / waybar / mako / wofi / swaylock / wlogout — Linux desktop layer.
- snapper / btrfs / cachyos-bore kernel — Linux-only.
- Apple ID + iCloud + Find My + iMessage + FaceTime + App Store.
- Bluetooth (powered off; re-enable explicitly if you add a peripheral).
- AirDrop / Handoff / Continuity / Universal Clipboard.
- BSD audit (auditd) — removed in Sequoia.
- Tier 4 (kernel sysctls, systemd-homed, NixOS) — N/A on macOS.

## Quick handles

```fish
# Common ops
ssh mac                       # from Arch
limactl shell arch            # into the Mac's Arch VM
sudo pfctl -s rules           # current pf
sudo lsof -nP -iUDP:53        # who's on port 53 (should be unbound)
sudo log show --predicate 'process == "unbound"' --last 10m
sudo log show --predicate 'process == "osqueryd"' --last 10m
mise ls                       # toolchain pin
cargo check --workspace       # in ~/Projects/engine
```
