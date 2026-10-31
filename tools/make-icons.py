#!/usr/bin/env python3
"""Generate the PNG app icons for SwimSet.

Requires Pillow:  python3 -m pip install Pillow
Run from the repo root:  python3 tools/make-icons.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "icons"

BG = "#062a3a"
GLOW = "#0b3b4f"
WAVE_DARK = "#0ea5e9"
WAVE_LIGHT = "#2a94c3"  # #38bdf8 at 72% over the background
WHITE = "#f8fafc"
SS = 4  # supersampling factor


def wave_points(y: float, amplitude: float, periods: float) -> list[tuple[float, float]]:
    points = []
    steps = 240
    for i in range(steps + 1):
        t = i / steps
        x = 72 + (440 - 72) * t
        points.append((x, y - amplitude * math.sin(2 * math.pi * periods * t)))
    return points


def draw_icon(size: int, *, full_bleed: bool = False) -> Image.Image:
    big = size * SS
    k = big / 512
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if full_bleed:
        draw.rectangle([0, 0, big, big], fill=BG)
        scale, offset = 0.8, (512 - 512 * 0.8) / 2
    else:
        draw.rounded_rectangle(
            [0, 0, big - 1, big - 1], radius=112 * k, fill=BG
        )
        scale, offset = 1.0, 0.0

    def point(x: float, y: float) -> tuple[float, float]:
        return ((offset + x * scale) * k, (offset + y * scale) * k)

    def radius(value: float) -> float:
        return value * scale * k

    # decorative circle, clipped by the icon edge
    cx, cy, r = 430, 86, 150
    draw.ellipse(
        [point(cx - r, cy - r), point(cx + r, cy + r)], fill=GLOW
    )

    def stroke_path(points, width, colour):
        """Stamp overlapping discs along a path for a smooth round stroke."""
        r = radius(width) / 2
        for x, y in points:
            px, py = point(x, y)
            draw.ellipse([px - r, py - r, px + r, py + r], fill=colour)

    for base_y, amplitude, width, colour in (
        (302, 64, 34, WAVE_DARK),
        (394, 64, 26, WAVE_LIGHT),
    ):
        stroke_path(wave_points(base_y, amplitude, 2), width, colour)

    # swimmer head, tucked next to the leading arm
    hx, hy, hr = 174, 176, 36
    draw.ellipse(
        [point(hx - hr, hy - hr), point(hx + hr, hy + hr)], fill=WHITE
    )

    # swimmer arm: shoulder to hand, with a slight bend
    arm = []
    a, b, c = (212, 214), (298, 168), (372, 198)
    for i in range(48):
        t = i / 47
        if t < 0.5:
            u = t / 0.5
            arm.append((a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u))
        else:
            u = (t - 0.5) / 0.5
            arm.append((b[0] + (c[0] - b[0]) * u, b[1] + (c[1] - b[1]) * u))
    stroke_path(arm, 30, WHITE)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    ICONS.mkdir(exist_ok=True)
    outputs = [
        ("icon-512.png", 512, False),
        ("icon-192.png", 192, False),
        ("favicon-32.png", 32, False),
        ("icon-maskable-512.png", 512, True),
    ]
    for name, size, bleed in outputs:
        path = ICONS / name
        draw_icon(size, full_bleed=bleed).save(path, optimize=True)
        print(f"wrote {path.relative_to(ROOT)} ({size}x{size})")


if __name__ == "__main__":
    main()
