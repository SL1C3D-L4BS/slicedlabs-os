
# [ENGINE] brand bible
Canonical identity for the [ENGINE] surface area: terminal, compositor, streams, YouTube videos, Discord embeds. Every visual decision flows from `system/tokens.toml`.

## Palette
Source: `system/tokens.toml` `[color]`.

| Token         | Hex        | Where it shows up                                              |
|---------------|------------|----------------------------------------------------------------|
| `bg`          | `#1E1E1E`  | Default surface — terminal, waybar bar, compositor background. |
| `bg_alt`      | `#2B2B2B`  | Chips, cards, raised surfaces (one step above `bg`).           |
| `fg`          | `#F7F6F2`  | Body text.                                                     |
| `fg_muted`    | `#B8A789`  | Secondary text, inactive workspace labels, timestamps.         |
| `primary`     | `#2961B1`  | Royal Blue — engine, focus, brand mark, links.                 |
| `secondary`   | `#64A8E5`  | Sky Blue — comms, paths, version chips, informational accents. |
| `tertiary`    | `#D9892B`  | Golden Orange — stream, engine-status chip, alerts/warnings.   |
| `error`       | `#D95C5C`  | Coral Red — critical states, urgent notifications.             |
| `selection`   | `#1A3D6F`  | Deep Ocean — active workspace, terminal text selection.        |
| `inactive`    | `#3D3528`  | Inactive borders, dividers.                                    |
| `warm_shadow` | `#1A1612`  | Wallpaper seat gradient, shadow gradient stop.                 |

Translucent variants live in `[color_rgba]` (hex-with-alpha for niri + mako) and `[color_css]` (CSS `rgba()` for waybar + wofi). Shadow tints in `[shadow]`.

## Typography
Source: `system/tokens.toml` `[font]`.

| Token     | Value                       | Use                                       |
|-----------|-----------------------------|-------------------------------------------|
| `mono`    | JetBrainsMono Nerd Font     | Body, code, waybar, ghostty.              |
| `display` | Geist Mono                  | Headings, [ENGINE] mark, thumbnail titles.|

Fallback chain (configured in `fontconfig/.config/fontconfig/fonts.conf`):
`Geist Mono` → `JetBrainsMono Nerd Font` → `monospace`.

Type scale (work in [ENGINE] design ratios):
- Body: 13px
- UI: 11px
- Lower-third title: 36px display
- Thumbnail title: 120-160px display
- Stream "starting soon" timer: 96px display

## Spacing
- Base gap: 8px (`geom.gap`)
- Small radius: 4px (`geom.radius_sm`)
- Default radius: 6px (`geom.radius`)
- Large radius: 12px (`geom.radius_lg`) — window corners
- Border thickness: 2px (`geom.border`)

Padding follows the 4/8/12/14/16 scale. Avoid one-off values.

## Motion
Source: `system/tokens.toml` `[motion]`.

| Token       | Value     | Use                                |
|-------------|-----------|------------------------------------|
| `quick_ms`  | 120ms     | Hover, click feedback, micro-state.|
| `normal_ms` | 200ms     | Window open/move/resize.           |
| `slow_ms`   | 380ms     | Workspace switch, lower-third in.  |
| `ease`      | cubic-bezier(0.2, 0.8, 0.2, 1.0) | Default ease curve.|

All transitions use `ease`. Slide direction follows reading order (top→down, left→right) unless contextually opposite.

## Voice & tone
- **Concise**: every word earns its place. No "essentially", "really", "I think". No emojis in tracked content.
- **Technical**: assumes the audience is a working engineer. Use the specific term; gloss only if non-obvious.
- **Direct**: imperative for instructions ("clone the repo"), present-indicative for state ("CI runs on every push").
- **Grounded**: claims point at code, commits, or measurements. Avoid superlatives without numbers.

Naming conventions:
- `[ENGINE]` always in brackets, all caps — never "Engine", "the engine", "engine framework".
- Crate names: `engine-<noun>` (engine-raster, engine-render, …).
- Title pattern for devlog content: `[ENGINE] Devlog #N — <topic>`.

## Audio identity
- Mic chain: WaveXLR-Pro EasyEffects preset (RNNoise → Gate → 4-band EQ → Comp → De-esser → Limiter). See `easyeffects/.config/easyeffects/output/WaveXLR-Pro.notes.md` for stage rationale (TODO).
- 3-second sonic logo for intro/outro stings: TBD (Phase E.8 deliverable, ~120 BPM, primary key).

## Asset inventory
| Path                                  | Type              | Renderer            | Used by                      |
|---------------------------------------|-------------------|---------------------|------------------------------|
| `logo/engine-mark.svg.tmpl`           | Vector mark       | render-templates    | thumbnails, intros, favicon. |
| `scenes/lower-third.html`             | OBS browser scene | (none, HTML)        | OBS Engine/Live + Webcam.    |
| `scenes/starting-soon.html`           | OBS browser scene | (none, HTML)        | OBS Starting Soon.           |
| `scenes/brb.html`                     | OBS browser scene | (none, HTML)        | OBS BRB.                     |
| `scenes/brand.css.tmpl`               | Shared CSS        | render-templates    | All scene HTML files.        |
| `thumbnails/thumbnail-template.svg.tmpl` | Inkscape layered | render-templates → Inkscape | YouTube thumbnails. |

## Cross-surface contracts
- All [color] tokens render unchanged in: ghostty terminal, waybar, mako, wofi, niri, scene HTML, thumbnails, YouTube descriptions. A palette change touches `tokens.toml` only and rerendering propagates.
- Font fallback chain ensures any host without Geist Mono installed degrades gracefully to JBM Nerd Font.
- The [ENGINE] mark is the single brand identifier. Avoid logo variations; if a surface needs scale options, regenerate from `logo/engine-mark.svg.tmpl` with the right output size.
