#!/usr/bin/env python3
"""color — OKLCH ⇄ sRGB for the SlicedLabs design cascade.

Dependency-free. The token SSOT may express identity/derived hues in OKLCH
(perceptually-even lightness across hues — the right space for the Liquid-Glass
identity ramp); the render-* generators call `to_hex()` to bake sRGB for QML /
Textual / CSS, which know nothing about OKLCH.

OKLab matrices: Björn Ottosson, "A perceptual color space for image processing".

CLI:
  color.py hex2oklch '#D85A30'      → oklch(L C h)
  color.py oklch2hex 'oklch(...)'   → #RRGGBB
  color.py --anchors                → tokens-ready identity + family anchors (oklch), verified
  color.py --ramps                  → the derived 10-step tonal ramps (50…900) per hue
  color.py --selftest               → round-trip every anchor + the ramp law; nonzero on drift

Guarantee #3 (ownership): the identity + family hex anchors round-trip EXACTLY at
8-bit, so `engine` always resolves to #CA691F. `--selftest` is the gate (wired into
verify-*). Liquid Retina v3 adds the ramp law: every hue derives a 10-step tonal
ramp (50 lightest … 900 darkest) at render time — anchors are the only stored
truth; step 500 IS the anchor; step 200 must clear the WCAG contrast floor on bg.
"""
from __future__ import annotations

import math
import re
import sys

# The eight workspace identity anchors — Liquid Retina v3 wheel (the design law
# lives at ~/SlicedLabs/library/codex/20-architect/design-language.md). Spokes
# spread across the wheel at matched perceptual lightness (L≈0.623); these are
# the canonical sRGB targets the OKLCH stored in tokens.toml must bake back to
# exactly.
ANCHORS: dict[str, str] = {
    "coding": "#308BDD",      # blue       h 249.8
    "research": "#976BDA",    # purple     h 299.9
    "engine": "#CA691F",      # orange     h  52.2
    "browser": "#279B89",     # teal       h 179.8
    "monitoring": "#419F39",  # green      h 142.0
    "streaming": "#CE5495",   # magenta    h 350.0
    "gaming": "#E24B49",      # red        h  25.1
    "media": "#A4821F",       # gold       h  88.3
}

# Extended accent families (v3) — interleaved half-spoke hues at the same
# perceptual lightness; the vocabulary for semantic tiers, glass tints,
# gradients, and bright accents. Same exact-bake guarantee as the identities.
FAMILIES: dict[str, str] = {
    "lavender": "#6C7BE8",    # h 274.8 — between coding and research
    "orchid": "#BC5DB6",      # h 329.7 — between research and streaming
    "jade": "#3D9C6F",        # h 159.7 — between browser and monitoring
    "lime": "#7E9136",        # h 120.0 — between monitoring and media
    "tangerine": "#D36035",   # h  40.1 — between gaming and engine
    "gold": "#9A8636",        # h  95.2 — between media and lime
}

# The tonal-ramp law (v3): 10 steps per hue, lightest→darkest. Step 500 rides
# the anchor's own L at full chroma (== the anchor, exactly); every other step
# pins L and scales chroma, gamut-clamped so hue never bends from channel
# clipping. Roles: 50–300 text tiers · 400–500 accents · 600 hover ·
# 700 borders · 800–900 surfaces/glass tints.
RAMP_STEPS: tuple[tuple[str, float | None, float], ...] = (
    ("50", 0.95, 0.22),
    ("100", 0.90, 0.35),
    ("200", 0.82, 0.55),
    ("300", 0.75, 0.74),
    ("400", 0.69, 0.90),
    ("500", None, 1.00),   # None → the anchor's own L
    ("600", 0.53, 0.92),
    ("700", 0.44, 0.78),
    ("800", 0.34, 0.60),
    ("900", 0.25, 0.42),
)

# Mirrors tokens.toml [color].bg / [glass].contrast_floor — the selftest makes
# the readability law executable without color.py growing a tokens dependency.
_BG_DARK = "#1E1E1E"
_CONTRAST_FLOOR = 4.5

_OKLCH_RE = re.compile(
    r"^\s*oklch\(\s*([0-9.]+%?)\s+([0-9.]+)\s+(-?[0-9.]+)\s*\)\s*$", re.IGNORECASE
)
_HEX_RE = re.compile(r"^#?([0-9a-fA-F]{6})$")


# ---- sRGB transfer ---------------------------------------------------------
def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _linear_to_srgb(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


# ---- hex ⇄ linear rgb ------------------------------------------------------
def hex_to_linear(hexstr: str) -> tuple[float, float, float]:
    m = _HEX_RE.match(hexstr.strip())
    if not m:
        raise ValueError(f"not a 6-digit hex colour: {hexstr!r}")
    h = m.group(1)
    r, g, b = (int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    return _srgb_to_linear(r), _srgb_to_linear(g), _srgb_to_linear(b)


def linear_to_hex(lr: float, lg: float, lb: float) -> str:
    out = []
    for c in (lr, lg, lb):
        s = _linear_to_srgb(c)
        s = 0.0 if s < 0.0 else 1.0 if s > 1.0 else s  # gamut clamp
        out.append(round(s * 255))
    return "#{:02X}{:02X}{:02X}".format(*out)


# ---- linear rgb ⇄ OKLab ----------------------------------------------------
def linear_to_oklab(r: float, g: float, b: float) -> tuple[float, float, float]:
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = (math.copysign(abs(v) ** (1 / 3), v) for v in (l, m, s))
    return (
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    )


def oklab_to_linear(L: float, a: float, b: float) -> tuple[float, float, float]:
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = (v**3 for v in (l_, m_, s_))
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


# ---- OKLCH front door ------------------------------------------------------
def hex_to_oklch(hexstr: str) -> tuple[float, float, float]:
    L, a, b = linear_to_oklab(*hex_to_linear(hexstr))
    C = math.hypot(a, b)
    h = math.degrees(math.atan2(b, a)) % 360.0
    return L, C, h


def oklch_to_hex(L: float, C: float, h: float) -> str:
    rad = math.radians(h)
    return linear_to_hex(*oklab_to_linear(L, C * math.cos(rad), C * math.sin(rad)))


def format_oklch(L: float, C: float, h: float) -> str:
    return f"oklch({L:.5f} {C:.5f} {h:.3f})"


def parse_oklch(s: str) -> tuple[float, float, float]:
    m = _OKLCH_RE.match(s)
    if not m:
        raise ValueError(f"not an oklch() colour: {s!r}")
    lraw, craw, hraw = m.groups()
    L = float(lraw[:-1]) / 100.0 if lraw.endswith("%") else float(lraw)
    return L, float(craw), float(hraw)


# ---- gamut, contrast, ramps (v3) -------------------------------------------
def _in_gamut(L: float, C: float, h: float, eps: float = 1e-4) -> bool:
    rad = math.radians(h)
    rgb = oklab_to_linear(L, C * math.cos(rad), C * math.sin(rad))
    return all(-eps <= c <= 1.0 + eps for c in rgb)


def max_chroma(L: float, h: float) -> float:
    """Largest in-sRGB-gamut chroma at this (L, h), via binary search."""
    lo, hi = 0.0, 0.5  # sRGB never exceeds C≈0.37
    for _ in range(40):
        mid = (lo + hi) / 2.0
        if _in_gamut(L, mid, h):
            lo = mid
        else:
            hi = mid
    return lo


def _rel_luminance(hexstr: str) -> float:
    lr, lg, lb = hex_to_linear(hexstr)
    return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb


def contrast(hex_a: str, hex_b: str) -> float:
    """WCAG contrast ratio between two sRGB hex colours (1.0 … 21.0)."""
    la, lb = _rel_luminance(hex_a), _rel_luminance(hex_b)
    lighter, darker = max(la, lb), min(la, lb)
    return (lighter + 0.05) / (darker + 0.05)


def ramp(L: float, C: float, h: float) -> dict[str, str]:
    """Derive the 10-step tonal ramp for an anchor. Step 500 == the anchor hex
    exactly (same L, full C); other steps pin L and scale C, clamped to 98% of
    the gamut edge so clipping never bends the hue."""
    out: dict[str, str] = {}
    for step, step_l, c_scale in RAMP_STEPS:
        sl = L if step_l is None else step_l
        sc = min(C * c_scale, 0.98 * max_chroma(sl, h))
        if step_l is None:
            sc = C  # the anchor itself — bake exactly, no clamp drift
        out[step] = oklch_to_hex(sl, sc, h)
    return out


def ramp_for_hex(hexstr: str) -> dict[str, str]:
    return ramp(*hex_to_oklch(hexstr))


def to_hex(value: object) -> str | None:
    """If `value` is an oklch()/hex colour, return '#RRGGBB'; else None.

    The renderers call this to normalise any colour token to sRGB hex. rgba()/
    plain strings return None so callers keep their existing handling.
    """
    s = str(value).strip()
    if _OKLCH_RE.match(s):
        return oklch_to_hex(*parse_oklch(s))
    m = _HEX_RE.match(s)
    if m:
        return "#" + m.group(1).upper()
    return None


# ---- CLI -------------------------------------------------------------------
def _selftest() -> int:
    bad = []
    every = {**ANCHORS, **FAMILIES}
    for name, hx in every.items():
        rt = oklch_to_hex(*hex_to_oklch(hx))
        if rt.upper() != hx.upper():
            bad.append(f"  {name}: {hx} → {format_oklch(*hex_to_oklch(hx))} → {rt}")
    if bad:
        print("color --selftest: ROUND-TRIP DRIFT (guarantee #3 broken):")
        print("\n".join(bad))
        return 1

    # The ramp law: step 500 IS the anchor; L strictly descends 50→900; the
    # text tier (200) clears the WCAG floor on the dark bg.
    ramp_bad = []
    descend = [l for _, l, _ in RAMP_STEPS if l is not None]
    if descend != sorted(descend, reverse=True):
        ramp_bad.append("  RAMP_STEPS lightness is not strictly descending")
    for name, hx in every.items():
        r = ramp_for_hex(hx)
        if r["500"].upper() != hx.upper():
            ramp_bad.append(f"  {name}: ramp 500 {r['500']} != anchor {hx}")
        c = contrast(r["200"], _BG_DARK)
        if c < _CONTRAST_FLOOR:
            ramp_bad.append(
                f"  {name}: ramp 200 {r['200']} contrast {c:.2f} < {_CONTRAST_FLOOR} on {_BG_DARK}"
            )
    if ramp_bad:
        print("color --selftest: RAMP LAW BROKEN:")
        print("\n".join(ramp_bad))
        return 1

    print(
        f"color --selftest: ✓ all {len(ANCHORS)} identity + {len(FAMILIES)} family "
        f"anchors round-trip exactly; ramp law holds (500==anchor · L descends · "
        f"200 ≥ {_CONTRAST_FLOOR}:1 on bg)"
    )
    return 0


def _anchors() -> int:
    rc = 0
    for title, table in (("[color] identities", ANCHORS), ("[family]", FAMILIES)):
        print(f"# {title} — generated by `color.py --anchors`")
        for name, hx in table.items():
            L, C, h = hex_to_oklch(hx)
            rt = oklch_to_hex(L, C, h)
            flag = "" if rt.upper() == hx.upper() else f"   # ⚠ bakes {rt}, not {hx}"
            if flag:
                rc = 1
            print(f'{name:<11} = "{format_oklch(L, C, h)}"   # {hx}{flag}')
    return rc


def _ramps() -> int:
    print("# derived tonal ramps (50…900) — anchors are the only stored truth;")
    print("# generators synthesize these at render time via lib/color.ramp()")
    steps = [s for s, _, _ in RAMP_STEPS]
    for name, hx in {**ANCHORS, **FAMILIES}.items():
        r = ramp_for_hex(hx)
        print(f"\n{name} ({hx}):")
        for s in steps:
            print(f"  {name}_{s:<4} {r[s]}")
    return 0


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    cmd = argv[0]
    if cmd == "--selftest":
        return _selftest()
    if cmd == "--anchors":
        return _anchors()
    if cmd == "--ramps":
        return _ramps()
    if cmd == "hex2oklch" and len(argv) > 1:
        print(format_oklch(*hex_to_oklch(argv[1])))
        return 0
    if cmd == "oklch2hex" and len(argv) > 1:
        print(oklch_to_hex(*parse_oklch(argv[1])))
        return 0
    print(f"color: unknown command {cmd!r}; see --help", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
