# The [ENGINE] Workstation — Design Language (2026)

One design language, end to end: **kernel → audio → compositor → bar → editor →
the engine itself → the explainer about the engine.** Every layer reads from one
source of truth and obeys the same vocabulary, so the machine reads as a single
designed object rather than a pile of configs.

This document is the *why*. The *what* is enforced in code: `system/tokens.toml`
(SSOT), `bin/.local/bin/render-templates` (cascade), and the
`docs/DESIGN-AUDIT-2026-05-28.md` token-purity audit (0 raw hex in templates,
verified by `verify-gaming.sh`).

## 1. First principles

1. **Single source of truth.** Colour, type, glyph, motion, spring, geometry,
   opacity, blur — all live in `system/tokens.toml`. Nothing downstream invents a
   value. `render-templates` substitutes `{{section.key}}` into every `.tmpl`;
   `render-engine-palette` renders the same tokens into the engine's Rust
   `palette.rs`. The bar and the engine cannot disagree about "Royal Blue".
2. **Declarative registries → generators → rendered output.** Tabs
   (`waybar/.../tabs.toml` → `render-waybar`), workspace scenes
   (`sliced-engine/.../workspaces.toml` → `lib/scene.sh`), agents
   (`prompts/roles/*` → `render-prompts`). Hand-editing generated regions is
   forbidden; you change the registry and regenerate.
3. **Idempotent + reproducible.** A 26-layer `bootstrap.sh` takes a fresh
   Arch+Niri box to the full stack; every step is guarded. Package reality is
   captured by `snapshot-packages`, not hand-maintained.
4. **Signal, not decoration.** Motion and colour mean something. The bar only
   animates living state (build / REC / LIVE / urgent); windows are uniform
   frosted glass (focus is signalled by ring + shadow, never by greying).
5. **Governed autonomy.** The in-house AI team is cost-capped *and the cap is
   enforced* (`hooks/cost_cap.enforce` — the single paid chokepoint), audited
   (`audit.ndjson`), and observable. Capability without a budget is a liability.

## 2. The cascade (hardware → explainer)

| Layer | Artifact | Reads from |
|---|---|---|
| Kernel / scheduler | `linux-cachyos-bore` + sched-ext (`scx_rusty`), Btrfs+LUKS, systemd-boot UKI | — |
| Audio | Wave XLR → EasyEffects chain → `easyeffects_source` (processed mic) | `easyeffects/`, [[streaming-setup]] |
| Compositor | niri: dual-kawase `[blur]`, tactile `[spring]`, uniform `[opacity]` frosted glass | `tokens.toml` → `niri/config.kdl.tmpl` |
| Bar | Waybar fused instrument-cluster, **[ENGINE] cap centered at `bar_center`** | `tabs.toml` + `tokens.toml` |
| Launcher / control | wofi command palette (`sliced-menu`, Mod+Alt+Space) + `slicedlabs` TUI Control tab | existing scripts (SSOT) |
| Editor | Neovim colourscheme | `tokens.toml` → nvim lua |
| Workspace scenes | per-workspace canonical tools placed in columns | `workspaces.toml` → `lib/scene.sh` |
| Engine | `engine-ui` Rust `palette.rs` (zero-dep consts) | `tokens.toml` → `render-engine-palette` |
| Explainer | Manim scenes hardcode the same hexes | `docs/anim/` → `manim-render` |

## 3. Token vocabulary (`system/tokens.toml`)

- `[color]` / `[color_light]` — base + 7 workspace identities (Royal/Sky/Golden/
  Coral/Lime/Cyan/Olive) + 4 overlay-HUD hues (Violet/Seafoam/Orchid/Rose).
  Nature-inspired; cool blues for work → warm triad for signalling. Dark/light
  variants are full companions (`render-templates --variant=light`).
- `[color_css]` / `[color_rgba]` / `[color_raw]` — the same palette in the
  notations each consumer needs (GTK rejects 8-digit hex; Niri wants hex; ANSI
  wants raw). One palette, three dialects — never three palettes.
- `[font]` — perfect-fifth (1.5) modular scale; JetBrainsMono Nerd + Geist Mono.
- `[icon]` — Nerd Font glyph law, rendered to `scripts/lib/glyphs.sh`. Glyphs are
  *content*, sourced once.
- `[motion]` (quick/normal/slow/pulse + one easing) and `[spring]` (niri damping/
  stiffness/epsilon) — the feel of the machine, quantified.
- `[geom]` — 8pt grid; everything derives from the 4px atom. New in this build:
  `left_reserve` + `bar_center` (cap-centering geometry).
- `[opacity]` / `[shadow]` / `[blur]` — frosted-glass depth, in logical px.

## 4. Intellectual foundations

The disciplines this system encodes (full list + editions in
`docs/book-recommendations-2026.md`):

- **Module depth & clarity** — Ousterhout, *A Philosophy of Software Design*;
  Beck, *Tidy First?* → the token SSOT, the registry→generator pattern, naming.
- **Cognition** — Hermans, *The Programmer's Brain* → colour/glyph signalling to
  minimise working-memory load; one identity per workspace.
- **Data-intensive & DB internals** — Kleppmann; Petrov → the data/obs mesh.
- **Observability** — Majors et al. → OTel/Loki/Tempo, structured audit, the
  cost ledger.
- **Performance** — Gregg, *BPF Performance Tools* → bpftrace/flamegraph wiring.
- **Game-engine design** — Lengyel, *FGED* → the engine itself.

The dotfiles are themselves a teaching artifact: reading `tokens.toml` teaches
the discipline of a principled visual language.

## 5. How to extend without breaking the language

- New colour/dimension/glyph → `tokens.toml`, then `render-templates`. Never inline.
- New bar chip → `tabs.toml`, then `render-waybar && render-templates`.
- New workspace tool → `workspaces.toml` (`cockpit --list` to see the registry).
- New palette action → reuse an existing script in `sliced-menu` + the TUI Control
  tab; don't fork behaviour.
- Verify with `verify-gaming.sh` (must stay 0-fail) and the design-purity check
  (0 raw `#hex` in templates).

Related: [[waybar-tab-system]], [[terminal-agent-cockpit]],
[[polyglot-stack-2026-rollout]], [[engine-platform-project]], [[streaming-setup]].
