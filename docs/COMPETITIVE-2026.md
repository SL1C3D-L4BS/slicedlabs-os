# Competitive position (2026): vs Omarchy & ML4W

Where this rig sits against the two reference Linux-desktop projects of the
moment — **Omarchy** (DHH; Arch + Hyprland, omakase, 6 themes, `omarchy-menu`)
and **ML4W** (Stephan Raabe; Hyprland dotfiles + GTK Welcome/Settings apps,
Dotfiles Installer). Both are *beautiful onboarding ricers for general devs*.
This is a **principled engineering platform for one founder** — a different
category, not a nicer ricer.

## Scorecard

| Axis | Omarchy | ML4W | **This rig** |
|---|---|---|---|
| Target user | dev who wants a great desktop now | worker who wants a DE-like Hyprland | **solo founder building a Rust engine** |
| Theming | `colors.toml` → app configs (Ghostty/btop/Waybar/…) | GUI Settings app toggles | **`tokens.toml` → every app + Niri + Neovim + the engine's Rust palette**; full dark/light; motion/spring/blur/audio tokens too |
| Workspace model | static | static | **declarative per-workspace scenes** (`workspaces.toml` → `cockpit`) |
| Control surface | `Super+Alt+Space` menu | GTK Welcome + Settings apps | **wofi command palette + terminal-native TUI Control tab** (this build) |
| AI | none | none | **13-role cost-capped, audited, RAG-over-books team** (`slicedlabs`) |
| Provisioning | installer script | installer / Live ISO | **idempotent 26-layer `bootstrap.sh`**, snapshot-backed, secret-aware (sops+age, gitleaks) |
| Compositor | Hyprland | Hyprland | **niri** (scrolling, native blur, spring physics) |
| Observability | — | — | **OTel/Loki/Tempo/Prometheus mesh + audit ledger + cost gauge** |
| Reproducible to a 2nd host | partial | partial | **yes** (Mac Air + Lima VM tracked; tracked-template/untracked-include secret split) |

## What we adopt (and did, this build)

- **A command menu** (Omarchy's `Super+Alt+Space`). Adopted as `sliced-menu`
  on **Mod+Alt+Space** — but wofi-native and built *over existing scripts*
  (`ricing-variant`, `waybar-density`, `waybar-hud`, `dev|ai-stack-{up,down}`,
  `cockpit`, `slicedlabs`) so it can never drift from the system.
- **A settings surface** (ML4W's Settings app). Adopted as the **TUI Control
  tab** (`Ctrl+6` in `slicedlabs`): theme/density/stack-up·down/scene re-layout
  + live state — terminal-native, on-brand, no GTK app to maintain.
- **A theme system.** Already surpassed: one `tokens.toml` reaches further than
  Omarchy's `colors.toml` (it also themes Niri springs, the engine's Rust
  palette, and the Manim explainers).

## What we deliberately reject

- **A GTK settings GUI** (ML4W). Off-brand for a terminal-first engineer; the
  cockpit + palette + `tokens.toml` cover it without a parallel app to maintain.
- **Distro/ISO packaging** (Omarchy/ML4W). The deliverable is a *reproducible
  dotfiles tree + bootstrap*, not a distro. Different goal.
- **Hyprland.** niri's scrolling model + native blur + spring physics is the
  chosen substrate; the design language is built around it.
- **A theme marketplace.** One coherent, documented language (see
  `DESIGN-LANGUAGE-2026.md`) beats infinite skins.

## The one-line differentiator

> Omarchy and ML4W make Linux *beautiful to start*. This rig makes one founder's
> machine a **coherent engineering platform** — a single design language from the
> kernel scheduler to the engine's own UI, an in-house AI workforce with
> enforced cost governance, declarative workspace scenes, and a full
> observability mesh — all reproducible from one idempotent bootstrap.

Related: [[engine-platform-project]], [[polyglot-stack-2026-rollout]],
[[terminal-agent-cockpit]], [[waybar-tab-system]].
