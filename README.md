# .dotfiles

Arch + Niri workstation configuration. Stow-deployed, token-rendered, secret-aware.

**New here?** → **[docs/START-HERE.md](docs/START-HERE.md)** (the 10-minute tour) · **[docs/INDEX.md](docs/INDEX.md)** (every doc, beginner → architect).

## Repository layout

- `<package>/` — GNU Stow package. `cd ~/.dotfiles && stow <package>` symlinks its contents into `$HOME`.
- `system/` — host-level configuration: `tokens.toml` (design tokens), `.gitleaks.toml` (leak-detection rules + path allowlist), `etc/` (root-owned files copied by `bootstrap.sh`), `git-hooks/pre-commit` (gitleaks scan), and inventory snapshots (`packages.txt`, `aur-packages.txt`, `services.txt`).
- `bin/` — operator scripts (stowed onto `$PATH`).
- `bootstrap.sh` — idempotent package installer + system bring-up, layered (`Layer 0` baseline → `Layer 7` appearance).

## Bootstrap order on a clean host

1. Clone with submodules (none yet, but reserved): `git clone git@github.com:SL1C3D-L4BS/env.git ~/.dotfiles`.
2. Install GPG, pass, age, sops baseline: `sudo pacman -S --needed pass age sops gnupg`.
3. Import or generate the user's GPG key, then `pass init <fingerprint>`.
4. Restore the age key (if multi-host) at `~/.config/sops/age/keys.txt` mode 600.
5. Run `bin/render-templates` to produce stow-deployable outputs from `system/tokens.toml`.
6. `stow <packages>` (see `system/services.txt` and `bootstrap.sh` for the canonical list).
7. Run `bin/render-secrets` to decrypt every `*.sops` file (now reachable via stow symlinks) into its sibling plaintext path.
8. `bin/install-hooks` to wire gitleaks into every relevant repo's pre-commit.
9. `./bootstrap.sh` — installs every package layer; idempotent.

## Design tokens & templates — Liquid Retina v3

`system/tokens.toml` is the *only* place colors, fonts, motion, spacing, and
the glass material live. **Anchors are the only stored colour truth**: the 8
workspace identities + 6 `[family]` accents are OKLCH anchors at matched
perceptual lightness (`bin/.local/bin/lib/color.py --selftest` pins the exact
sRGB bake); 10-step tonal ramps derive at render time (`{{ramp.coding_300}}`),
plus `{{vec3.*}}` (GLSL) and `{{rgb.*}}` (ANSI truecolor) namespaces.

Every `.tmpl` file references `{{section.key}}` placeholders.
`bin/render-templates` (with `--variant=dark|light` and `--look=clear`)
substitutes them next to the template; rendered outputs are gitignored — the
`.tmpl` is the tracked truth. Dedicated generators keep the non-template
surfaces in lockstep: `render-quickshell` (cockpit `Theme.qml` — glass tiers
base/focal/ultra, ramps API), `render-textual` (TUI palette + tcss),
`render-engine-palette` (the engine's `palette.rs`), `render-brand`
(wallpapers — `sl-wallpaper` for the liquid-retina art + per-hue moods).

The cascade today: niri · cockpit (Quickshell) · mako/wofi/swaylock/wlogout ·
ghostty/zellij/fish (the `[ansi]` content SSOT) · fastfetch (the SLICEDLABS
wordmark greeting) · nvim/vim schemes · qt6ct · OBS theme · GTK 3/4 · cava ·
spotify-player/lazygit/gh-dash/delta/btop · the Hermes web face
(`liquid-tokens.css`) · the engine. `sl-theme dark|light|clear` re-renders
and live-reloads the whole machine.

Adding a new templated file: write `<path>.tmpl` next to where the rendered
file should land, add the rendered path to `.gitignore`, and rerun
`bin/render-templates`. The law: `library/codex/20-architect/design-language.md`.
Gates: `verify-design-language` · `verify-tokens-drift` · `verify-terminal`.

## Secrets

Two stores:

- **`pass`** (GPG-encrypted line store) for paste-once values: bot tokens, stream keys, API tokens. Tree: `engine/`, `streaming/`, `infra/`, `services/`, `discord/`, `youtube/`.
- **`sops` + `age`** (file-encrypted, in-tree) for config blobs that need to live in this repo (e.g., `ssh/.ssh/config.d/local.conf.sops`). Convention: `<name>.sops` → `<name>` after `bin/render-secrets` runs. Age recipient(s) declared in `~/.dotfiles/.sops.yaml`; private key at `~/.config/sops/age/keys.txt` (mode 600, NEVER tracked).

Plaintext secrets never live in the repo. `~/.dotfiles/system/.gitleaks.toml` defines custom rules for RFC1918 IPs + MAC addresses (the leak class we hit on 2026-05-21), plus a global path allowlist for `~/.claude/.credentials.json`, `~/.password-store/`, `~/.gnupg/`. `bin/install-hooks` symlinks `system/git-hooks/pre-commit` into `.git/hooks/pre-commit` for every relevant repo.

## Multi-host

Today: a single host, `engine-workstation`. Future MacBook Air integration documented in `HOSTS.md`. Per-host overrides: stow packages that don't apply to a host are skipped at deploy time; host-private values live in untracked `.config.d/local.conf`-style includes (the split pattern documented in the auto-memory `dotfiles-secret-split`).

## Adjacent repositories

- `~/SlicedLabs/tools/engine/` — the [ENGINE] product (separate repo, `SL1C3D-L4BS/engine`).
- `~/SlicedLabs/tools/discord/` — the Discord MCP bot (separate repo, `SL1C3D-L4BS/discord-mcp`). Token in `pass discord/bot-token`.
- `~/.claude/projects/-home-doodlebob/memory/` — Claude auto-memory. Eventually symlinked into a `claude-memory/` stow package for versioning.

## Related design docs

- `~/Documents/network-security-design.md` — workstation network & security design, Tier 1 implemented, Tier 2/3 in progress.
- `~/.claude/plans/valiant-inventing-wolf.md` — the active 2026 modernization plan this README is part of executing.
