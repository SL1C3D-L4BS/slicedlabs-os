# Tooling Design Cascade (2026) — the whole stack speaks the language

> Take the desktop's design language — the **OKLCH identity ramp**, the **`[semantic]`
> role tier**, and the **hairline / weight-500 restraint** — all the way down to the
> terminal-engineer tooling: ghostty · zellij · nvim · vim · starship · bat · lazygit ·
> yazi · btop · fzf · delta · the menus. One `tokens.toml` SSOT, every tool in lockstep.

*This is the planned Track 8 (user request, 2026-05-31). Plan only — execute after approval.*

---

## Context — why

The desktop redesign is done: OKLCH identity, semantic tier, Liquid Glass, the governed-AI
Penalty Box. But a terminal-engineer lives in **ghostty + zellij + nvim** all day, and today
those still wear the *old* palette (they reference `{{color.primary}}`/`{{ansi.*}}` — stable,
but they predate the new identity/semantic system). The result: the desktop chrome speaks
2026, the tools speak 2025. This track makes the **whole stack** breathe the same language —
and unlocks the headline move below.

**The headline: the stack breathes the workspace identity.** The desktop already gives each
workspace a perceptually-even OKLCH hue (coding blue `#378ADD` … engine coral `#D85A30`).
Extend that *into the tools*: the nvim statusline, the zellij active-tab + frame, the starship
prompt accent, the fzf/yazi highlight — each tints to the **focused workspace's identity hue**.
Open the coding workspace and the whole terminal glows blue; jump to engine and it warms to
coral. No rice does this end-to-end. It's the SSOT cascade made visceral.

---

## Current state (audit)

| Tool | Theming surface | Token-driven today? | Gap |
|---|---|---|---|
| ghostty | `ghostty/.config/ghostty/config.tmpl` | ✅ `{{ansi.*}}` + `{{color.*}}` | uses old accent; no semantic/identity |
| zellij | `config.kdl.tmpl` + `layouts/*.tmpl` | ✅ `{{color.*}}` | active-tab/frame should take identity |
| nvim | `lua/engine/palette.lua.tmpl` → `colors/engine.lua` (custom scheme) | ✅ rich | diagnostics→semantic; statusline→identity |
| starship | `starship.toml.tmpl` | ✅ `{{color.*}}` | segment accent → identity; status → semantic |
| mako · wlogout · wofi · fuzzel | `*.tmpl` | ✅ | elevate to `[semantic]` roles |
| **bat** | none | ❌ | **new render target** (`.tmTheme` from tokens) |
| **lazygit** | none | ❌ | **new render target** (`config.yml.tmpl`) |
| **yazi** | none | ❌ | **new render target** (`theme.toml.tmpl`) |
| **btop** | none | ❌ | **new render target** (`.theme.tmpl`) |
| **fzf** | none | ❌ | **new render target** (`FZF_DEFAULT_OPTS` colors → `fish/conf.d`) |
| **delta** (git) | none | ❌ | **new render target** (gitconfig delta block) |

Token usage across all templates: `color` ×433 · `color_raw` ×37 · `ansi` ×31 · `font` ×25.
`render-templates` substitutes `{{section.key}}` from **any** tokens.toml section, so `[semantic]`
is already consumable as `{{semantic.text_primary}}` etc. — no generator change needed for the
already-templated tools.

---

## Design law (carried from the desktop)

1. **`[ansi]` stays the terminal palette** (16 colors) — never repoint it to identity, or `ls`
   colors and TUIs go feral. Identity/semantic ride *on top* of ANSI, on chrome (frames, tabs,
   statuslines, prompts, highlights, diagnostics).
2. **`[semantic]` for roles** — diagnostics/status/borders bind to `text_danger`/`text_info`/
   `border_*`, never raw hues. (`verify-design-language` extends to cover the tooling tmpls.)
3. **Identity for accent** — the one "brand" accent per surface = the workspace identity hue.
4. **Hairline / weight-500 restraint** — thin separators, medium emphasis, no heavy bold; match
   the cockpit's calm.
5. **Extend the cascade, never fork it** — every tool is `tokens.toml → render-* → config`.

---

## The identity-accent mechanism (the headline, two tiers)

**Tier A — static (baseline, low-risk).** Tools use the global accent (`color.primary`) +
`[semantic]`. Cohesive, simple, no runtime moving parts. Ship this first.

**Tier B — dynamic per-workspace identity (the wow).** The accent follows the focused workspace.
Two viable mechanisms (pick per tool):
- **Env at spawn**: `scene.sh`/the workspace launcher already knows the workspace; export
  `SL_IDENTITY=<hex>` when spawning a workspace's terminal. starship/fzf/zellij read it live
  (starship `os`/custom module, `FZF_DEFAULT_OPTS`, zellij theme via env). Cheap, immediate.
- **Cache + reload**: the cockpit already writes `~/.cache/waybar-active-tab`; a tiny watcher
  re-renders the per-tool accent file on workspace change (like `ricing-variant` does for
  dark/light). Heavier; only for tools that can hot-reload (nvim via autocmd + a uvar).

Recommend: **Tier A everywhere first**, then **Tier B via the spawn-env path** for starship +
zellij + fzf (instant, no daemon), and nvim via a `$SL_IDENTITY` autocmd. Skip Tier B for tools
that can't hot-recolor cheaply.

---

## Per-tool plan

**Already templated — elevate (Tier A now, Tier B where noted):**
- **ghostty** — keep `[ansi]` palette; set `cursor-color`/`selection` from `[semantic]`; the
  window `background-opacity` already glass-friendly. (Tier B: cursor = identity.)
- **zellij** — `themes` block: `fg/bg` from `[semantic]`, **active tab + frame highlight = the
  accent** (Tier A: `color.primary`; Tier B: `$SL_IDENTITY`). Hairline pane frames.
- **nvim** (`engine` colorscheme) — the richest win: map `DiagnosticError/Warn/Info/Hint` →
  `[semantic].text_danger/honey/text_info/…`; `StatusLine`/`Visual`/`CursorLineNr` accent →
  identity (Tier B via `$SL_IDENTITY` + a `ColorScheme`/`FocusGained` autocmd reading a uvar);
  Treesitter/LSP semantics keep the ANSI-derived palette. `vim` gets the static identity accent.
- **starship** — prompt char + the `directory`/`git_branch` accent = identity (Tier B env);
  `status`/`cmd_duration` → `[semantic]` danger/warn. Thin powerline → hairline plain.
- **mako/wlogout/wofi/fuzzel** — repoint borders/selection to `[semantic].border_info` +
  `text_*`; selection accent = identity.

**Not templated — add render targets (new `.tmpl`, all `[semantic]`/`[ansi]`-driven):**
- **bat** — generate `bat/themes/slicedlabs.tmTheme.tmpl` (syntax from `[ansi]`, UI/gutter from
  `[semantic]`); `bat --build-theme`. Set `--theme=slicedlabs`.
- **lazygit** — `config.yml.tmpl`: `gui.theme` borders/active = `[semantic]`/identity.
- **yazi** — `theme.toml.tmpl`: `[mgr]`/`[status]` hover + border = identity; `[semantic]` text.
- **btop** — `slicedlabs.theme.tmpl`: graphs in the cool→warm identity ramp; box outlines hairline.
- **fzf** — a `fish/conf.d/fzf-colors.fish.tmpl` exporting `FZF_DEFAULT_OPTS --color` from
  `[semantic]` + `$SL_IDENTITY` (hl/marker = identity).
- **delta** (git pager) — gitconfig `[delta]` block from `[semantic]` (plus/minus = success/danger).

---

## New / changed pieces

- **SSOT**: no new token sections needed — `[semantic]`, the identity ramp, and `[ansi]` already
  exist. Optionally add `[tooling]` for tool-specific knobs (e.g., nvim statusline style).
- **Generators**: reuse `render-templates` for all the `.tmpl`s. Add a tiny **`render-identity-env`**
  (writes `SL_IDENTITY=<hex>` for the focused workspace into the spawn env / a cache) for Tier B.
- **Scenes**: `lib/scene.sh` / the launcher export `SL_IDENTITY` when spawning a workspace's apps.
- **Verifiers**: extend **`verify-design-language`** to scan the tooling configs (no raw hex
  outside the `.tmpl` placeholders + generated themes); a **`verify-tooling`** that renders every
  tool's config and asserts it parses (ghostty `+show-config`, zellij `setup --check`, `bat
  --list-themes`, `btop --version` with the theme, nvim `-c 'colorscheme engine' -c q`).

---

## Execution order

1. **T8.0 — semantic adoption (Tier A, static).** Repoint the already-templated tools
   (ghostty/zellij/nvim/starship/mako/wlogout/wofi) to `[semantic]` + `color.primary` accent;
   `render-templates`; eyeball each. Lowest risk, immediate cohesion.
2. **T8.1 — new render targets.** bat · lazygit · yazi · btop · fzf · delta templates; wire into
   bootstrap + `render-templates`; `verify-tooling`.
3. **T8.2 — the headline (Tier B identity).** `render-identity-env` + scene export of
   `$SL_IDENTITY`; wire starship · zellij · fzf · nvim to the focused-workspace hue. Demo: jump
   workspaces, watch the whole terminal recolor.
4. **T8.3 — guardrails.** `verify-design-language` covers tooling; one render+parse pass per tool
   in `verify-all`.

## Verification gates

- Every tool's config renders + **parses** (per-tool check above) in `verify-tooling`.
- `verify-design-language`: no raw hex in any hand-written tool config (only `{{tokens}}`).
- Tier B: opening each workspace recolors starship/zellij/fzf/nvim to that workspace's hue;
  `[ansi]` (and therefore `ls`/TUIs) is unchanged.
- `verify-tokens-drift`-style: re-render is byte-stable; no uncommitted drift.

## Risks → owned

- **ANSI integrity** — never repoint `[ansi]`; identity/semantic only touch chrome. (Guard: a
  `verify-tooling` check that `[ansi]` keys are untouched by this track.)
- **Tier B cost** — env-at-spawn is free; avoid per-keystroke recolor. nvim recolor is autocmd
  on focus only.
- **bat/btop theme build** — both need a one-time build/registration step; fold into bootstrap +
  `verify-tooling` so a fresh install is correct.

## Delivered — 2026-05-31

The cascade is **live and gated** (`verify-tooling`, folded into `verify-all` — all green):

- **Headline (per-workspace identity).** `sl-identity` maps workspace→hex from `[color_raw]`;
  `scene.sh` exports `SL_IDENTITY` when a workspace's terminal spawns. **fzf**
  (`sl-fzf.fish.tmpl`, `FZF_DEFAULT_OPTS` from `[semantic]` + `$SL_IDENTITY`) and **nvim**
  (`engine.lua` chrome → `$SL_IDENTITY`) recolour to the focused workspace's hue; a hand-opened
  terminal falls back to the global accent. Static-colour tools (starship/zellij/ghostty) can't
  read env per-spawn — by design they carry the global accent.
- **btop** — new token-driven theme (`themes/slicedlabs.theme.tmpl`): graphs on the
  green→honey→coral signal ramp, hairline boxes, palette chrome. `btop.conf` stays unmanaged
  (btop rewrites it on exit); **bootstrap** deploys the read-only theme + sets
  `color_theme=slicedlabs` idempotently.
- **bat** — pinned to `theme=ansi`: the syntax pager rides the `[ansi]` SSOT, so it's always in
  sync with the terminal — no second palette to drift.
- **Audit finding:** ghostty / zellij / starship / mako / wofi / fish were **already fully
  token-driven** (0 raw hex; zellij's active tab already `color.primary`) — the cascade already
  reached them; nothing to elevate.
- **Guardrail:** `verify-tooling` asserts `[ansi]` is never repointed to an identity hue — the
  load-bearing rule that keeps `ls`/TUIs/bat legible while identity rides the chrome.

**Deliberately deferred** (not gaps): **delta** (lives in personal `~/.gitconfig`, outside the
dotfiles secret-split — not ours to template); **lazygit** (unconfigured; low value); **yazi**
(not installed); a richer truecolor **bat `.tmTheme`** (ansi is the SSOT-correct default).
