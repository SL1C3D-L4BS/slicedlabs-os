# SlicedLabs OS — System Map

> One owned, installable, Liquid-Glass, terminal-engineer operating environment:
> **SlicedLabs OS** (the env) + **[ENGINE]** (the Rust engine) + a constitutionally-governed
> local AI team (**Warden**, with a visible **Penalty Box**), driven by one token SSOT into
> three render targets. Host: CachyOS (Arch) + niri (Wayland).

## The cascade (single source of truth → render → targets)

```
system/*.toml ──▶ render-*  ──▶  generated outputs           consumed by
──────────────    ─────────      ──────────────────────      ─────────────────────────────
tokens.toml       render-quickshell  cockpit/generated/Theme.qml   the Cockpit GPU shell (QML)
  [color] OKLCH   render-textual     slicedlabs_team/generated/    the Console TUIs (Textual)
  [semantic]                           {palette.py,theme.tcss}
  [glass]         render-templates   ~/.config/**/*  (niri, ghostty,  the whole terminal stack
  [ansi]                               zellij, mako, fish, …)
  [cockpit]       render-keys        keys.json + niri binds + poster   keybinds everywhere
keys.toml         render-governance  cockpit/generated/governance.json Warden pill + modal + Console
governance.toml   color.py           oklch()→sRGB (shared by both renderers)
```

**Prime directive:** *extend the cascade, never fork it.* Every change flows `*.toml` → `render-*`
→ output; generated regions are never hand-edited. **Load-bearing rule:** content rides the `[ansi]`
terminal palette; chrome rides identity/semantic — never repoint `[ansi]` to an identity hue.

## Workspaces — 8 OKLCH identities (+ scratch)

| # | id | hue (dark) | # | id | hue (dark) |
|---|---|---|---|---|---|
| 1 | coding | `#378ADD` blue | 5 | monitoring | `#639922` green |
| 2 | research | `#7F77DD` violet | 6 | streaming | `#D4537E` magenta |
| 3 | engine | `#D85A30` coral | 7 | gaming | `#E24B4A` red |
| 4 | browser | `#1D9E75` teal | 8 | media | `#BA7517` amber |

`Mod+1..8` focus; **`desk`** (`Mod+9`) is a blank scratch workspace on DP-3. Scenes (apps + backing
services) stage on first focus from `sliced-engine/.config/sliced-engine/workspaces.toml` via
`lib/scene.sh`; `cockpit [ws]` re-realizes idempotently; `cockpit-selfheal` fills any login gap.

## Keys (a few load-bearing ones; full set: `Mod+Alt+K`)

- `Mod+1..8` workspaces · `Mod+9` desk · `Mod+Alt+Space` palette (`sliced-menu`)
- `Mod+Alt+K` keys modal · `Mod+Alt+C` Control Center · `Mod+5` monitoring cockpit
- Console TUI (`slicedlabs`): `Ctrl+1..9` tabs — Chat/Agents/Cost/Audit/Memory/Control/Penalty/Apps/Theme

## Boot contract (startup discipline)

Login starts **only**: niri + the staged WS1 scene · `quickshell.service` (the Cockpit HUD) ·
`warden.service` (governance freshness, idle). Observability (grafana/prometheus/pyroscope/alloy/
node-exporter/vector), printing (cups), and battery (upower) are **disabled at boot** — on-demand via
the native `slicedlabs monitor` TUI + the `monitoring-backends {up|down}` helper. Boot drop-ins cap
`systemd-networkd-wait-online` (`--any --timeout=5`) so DHCP never blocks the critical chain.
Firewall: **nftables** default-drop, trusting `lo` + `tailscale0` + WireGuard. Authored reproducibly
by `bootstrap.sh` → `layer_S_system_hardening`.

## Warden — local AI governance (the signature feature)

- **Policy SSOT:** `system/governance.toml` → `render-governance` → `cockpit/generated/governance.json`.
- **Engine:** `slicedlabs_team/warden/` — a hash-chained, **Ed25519-signed** SQLite **ledger**
  (`ledger.py`), a behavioural **Monitor** (`monitor.py`, wired at `crews._finish` — every crew run is
  recorded + benched if it breaches its per-run cost policy; pre-flight cost block stays in
  `hooks/cost_cap.py`), and the **Penalty Box** state machine (`state.py`).
- **CLI:** `warden {status,suspend,probation,rehab,retire,run-eval,verify,review-evidence,daemon}` (the
  fast standalone bin; `slicedlabs warden …` is the typed alternate). `warden verify` checks the chain +
  signatures.
- **Surfaces (one `governance.json`, three views):** the bar `agents · N benched` pill, the actionable
  Penalty-Box **modal** (review-evidence / rehab / retire / pass-eval), and the **Console Penalty Box**
  tab (`Ctrl+7`).

## Verify harness (the green check)

`verify-all` aggregates: `verify-{cockpit,gaming,governance,keys,tokens-drift,tooling,design-language,
workspace-remap,public-clean,boot-contract}` + `color.py --selftest`. `slicedlabs-os doctor` runs the
harness + service health. Python package gates (CI + local): `ruff` · `mypy --strict` · `basedpyright`
(on `warden/`) · `pytest`.

## Install ladder (the replicability rungs)

| Rung | How | What |
|---|---|---|
| **Try** | `iso/` archiso → `out/slicedlabs-os-*.iso` → boot a VM/USB | lean Arch base (niri+ghostty) → first-boot clones the **public** showcase → `bootstrap.sh` → desktop |
| **Install** | `slicedlabs-os install` (drives `bootstrap.sh` layers) | the full curated stack on an existing Arch/CachyOS host |
| **Declare** | `nix/` home-manager module (`flake.nix`) | the declarative seed of the config layer |

Secrets never ship: the ISO + showcase clone the **public** repo only; `verify-public-clean` (gitleaks
+ proprietary-path grep) gates any publish.

## Repo layout (`~/.dotfiles`)

- `system/` — token + policy SSOTs (`tokens.toml`, `keys.toml`, `governance.toml`) + tracked `etc/` drop-ins.
- `bin/.local/bin/` — the `render-*` generators, `verify-*` gates, `cockpit`/`scene.sh`, `warden`, `slicedlabs-os`, launchers.
- `quickshell/…/cockpit/` — the GPU shell (QML): bars, modals, services, shaders, `generated/`.
- `slicedlabs-team/` (submodule) — the Python AI team: agents/crews/tui + `warden/` engine.
- `niri/`, `zellij/`, `ghostty/`, `mako/`, `fish/`, … — token-driven `.tmpl` → rendered config (stowed).
- `iso/` — archiso profile + `build.sh`. `nix/` — home-manager module. `docs/` — this map + runbooks.
- `bootstrap.sh` — the idempotent layered installer (`A → 0..8 → B..S..R`).
