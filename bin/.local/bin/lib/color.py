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
  color.py --anchors                → tokens-ready identity ramp (oklch), verified
  color.py --selftest               → round-trip the 8 concept anchors; nonzero on drift

Guarantee #3 (ownership): the 8 concept hex anchors round-trip EXACTLY at 8-bit, so
`engine` always resolves to #D85A30. `--selftest` is the gate (wired into verify-*).
"""
from __future__ import annotations

import math
import re
import sys

# The eight workspace identity anchors from the design concept
# (~/Downloads/slicedlabs_desktop_concept.html). These are the canonical sRGB
# targets; the OKLCH stored in tokens.toml must bake back to exactly these.
ANCHORS: dict[str, str] = {
    "coding": "#378ADD",      # blue
    "research": "#7F77DD",    # violet
    "engine": "#D85A30",      # coral
    "browser": "#1D9E75",     # teal
    "monitoring": "#639922",  # green
    "streaming": "#D4537E",   # magenta
    "gaming": "#E24B4A",      # red
    "media": "#BA7517",       # amber
}

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
    for name, hx in ANCHORS.items():
        rt = oklch_to_hex(*hex_to_oklch(hx))
        if rt.upper() != hx.upper():
            bad.append(f"  {name}: {hx} → {format_oklch(*hex_to_oklch(hx))} → {rt}")
    if bad:
        print("color --selftest: ROUND-TRIP DRIFT (guarantee #3 broken):")
        print("\n".join(bad))
        return 1
    print(f"color --selftest: ✓ all {len(ANCHORS)} identity anchors round-trip exactly")
    return 0


def _anchors() -> int:
    print("# identity ramp — paste into [color]; generated by `color.py --anchors`")
    rc = 0
    for name, hx in ANCHORS.items():
        L, C, h = hex_to_oklch(hx)
        rt = oklch_to_hex(L, C, h)
        flag = "" if rt.upper() == hx.upper() else f"   # ⚠ bakes {rt}, not {hx}"
        if flag:
            rc = 1
        print(f'{name:<11} = "{format_oklch(L, C, h)}"   # {hx}{flag}')
    return rc


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    cmd = argv[0]
    if cmd == "--selftest":
        return _selftest()
    if cmd == "--anchors":
        return _anchors()
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
