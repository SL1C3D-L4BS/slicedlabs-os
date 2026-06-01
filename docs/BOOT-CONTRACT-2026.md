# Boot Contract 2026 — what the workstation brings up at login

> The promise: log in and the working stacks are *already there*. This is a contract,
> not an accident — `verify-boot-contract` (in `verify-all`) asserts every clause.

## At `niri-session` start (spawn-at-startup, niri config.kdl)

| Spawn | Brings up |
|---|---|
| `engine-wallpaper` / `engine-backdrop` | crisp desktop wallpaper + pre-blurred overview backdrop |
| `mako` · `mako-workspace-mode` | notifications (workspace-tinted) |
| `swayidle -w` | idle → lock |
| `easyeffects` (service + WaveXLR chain) | the mic processing graph |
| **`monitoring-stack`** | the **monitoring stack** on DP-3 (Grafana/Loki/Tempo/Pyroscope + htop/btop) |
| **`niri-workspace-launcher`** | **eager-stages the coding · browser · research stacks** (staggered, `--focus false`) |
| **`niri-autotile`** | dynamic full→halves tiling daemon (idle until a window opens/closes) |

## The eager-staged stacks (`workspaces.toml [meta].auto`)

Each lands on its own workspace and starts its backing services on first realize
(`lib/scene.sh`). Staggered (`sleep 2`) so the 4c/8t CPU isn't thundered; re-staged
idempotently on first focus.

| WS | Stack | Surfaces | Services |
|---|---|---|---|
| **WS1 coding** | full-stack dev cockpit | `ghostty -e zj coding` (code·debug·run·data·**obs**·mac) | `dev-stack-data`, `uair` |
| **WS2 research** | deep-work cockpit | `zj research` (study·architect·design·audit) + Firefox | — |
| **WS4 browser** | the web | Zen ‖ Firefox | — |
| **WS5 monitoring** | observability (DP-3) | `monitoring-stack` delegate | the `slicedlabs-observability` target |

**Opt-in (not auto):** engine (`Mod+Ctrl+E`), streaming (`Mod+Ctrl+S`), gaming
(`Mod+Ctrl+Shift+G`), media (`Mod+Ctrl+V`) — staged on demand via `cockpit <ws>`.

## Repair / re-stage

- `cockpit` — realize every auto stack (idempotent "fix my layout" button).
- `cockpit <ws>` — realize one.
- `slicedlabs-os doctor` — every `verify-*` gate + service health.

## Invariants (`verify-boot-contract`)

1. `[meta].auto` = `coding`, `browser`, `research`.
2. niri spawns `niri-workspace-launcher`, `monitoring-stack`, `niri-autotile`.
3. each auto workspace declares its scene (apps or delegate).
4. the coding stack starts `dev-stack-data`; monitoring lives on DP-3.
