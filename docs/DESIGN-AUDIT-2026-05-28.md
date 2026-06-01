# Design-system audit — 2026-05-28

Scope: every templated config under `~/.dotfiles/**/*.tmpl` (rendered from
`system/tokens.toml` by `render-templates`), plus the new engine palette cascade.

## Verdict: the workstation is already design-token-consistent.

- **0 raw `#hex` literals** outside `{{tokens}}` in any template — colours are
  100% token-sourced.
- **0 hardcoded Nerd-Font / PUA glyphs** in any template.
- **1 content-glyph gap** — starship `[rust] symbol = "🦀"` — now tokenised to
  `{{icon.rust}}`. Templates are 100% token-sourced after this pass.
- Geometry (`[geom]`), motion (`[motion]`), and ANSI palette are token-sourced
  wherever the app supports them.

## Per-template coverage

| Template | color | geom | motion | glyphs | notes |
|---|:--:|:--:|:--:|:--:|---|
| waybar/config.jsonc + style.css | ✓ | ✓ | ✓ | ✓ `{{icon.*}}` | fused-cluster redesign |
| waybar/scripts/lib/glyphs.sh | — | — | — | ✓ | `[icon]` → bash `$G_*` |
| niri/config.kdl | ✓ | ✓ (spring) | ✓ | n/a | active-gradient, springs |
| mako/config | ✓ | ✓ | n/a | n/a | urgency → brand tokens |
| wofi/style.css | ✓ | ✓ | n/a | n/a | styling only |
| wlogout/style.css | ✓ | ✓ | n/a | n/a | styling only |
| swaylock/config | ✓ | n/a | n/a | n/a | indicator-ring colours |
| ghostty/config | ✓ | n/a | n/a | n/a | ANSI + bg palette |
| starship.toml | ✓ | n/a | n/a | ✓ (rust) | 🦀 tokenised this pass |
| zellij/config.kdl | ✓ | n/a | n/a | n/a | theme palette |
| gtk 3/4 gtk.css | ✓ | ✓ | n/a | n/a | accent + radii |
| MangoHud.conf | ✓ | n/a | n/a | n/a | overlay colours |
| nvim engine/palette.lua | ✓ | n/a | n/a | n/a | tokens → Lua colorscheme |
| **engine-ui/theme/palette.rs** | ✓ | ✓ | ✓ | ✓ | **NEW: tokens → Rust** |

## Why the styling configs carry no `[icon]` glyphs

CSS/conf styling files (mako, wofi, wlogout, swaylock, gtk, ghostty) don't render
content glyphs — their icons come from each app's own font / SVG / layout system,
not the config. So the `[icon]` vocabulary is propagated only where glyphs are
*content*: Waybar chips, starship prompt symbols, and the engine bar. Injecting
glyphs into styling configs would be cargo-cult, not consistency.

## Cascade map — single source of truth: `system/tokens.toml`

```
tokens.toml ─ render-templates ──────────────→ 20 rendered configs (dark|light)
            ─ render-templates ──────────────→ scripts/lib/glyphs.sh  ([icon] → $G_*)
            ─ render-engine-palette (just gen-palette) → engine-ui/src/theme/palette.rs
            ─ render-prompts ────────────────→ .claude/agents/* + aider agents
```

Light variant: `render-templates --variant=light` (auto-switched by `waybard`,
manual `Mod+Alt+L`) re-themes every config above; the engine palette is
variant-agnostic const data (regenerate per active variant if a light engine
build is wanted).
