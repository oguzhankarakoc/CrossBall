#!/usr/bin/env python3
"""Professional App Store marketing screenshots from real simulator captures."""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

# App Store Connect exact sizes
IPHONE_SIZE = (1284, 2778)  # 6.5" accepted
IPAD_SIZE = (2048, 2732)  # 13" / 12.9" accepted

SRC_IPHONE = Path("/Users/oguzhankarakoc/Desktop/CrossBall-Real-Screenshots/App-Store-Upload/iPhone-6.9-inch")
SRC_IPAD = Path("/Users/oguzhankarakoc/Desktop/CrossBall-Real-Screenshots/App-Store-Upload/iPad-13-inch")
OUT = Path("/Users/oguzhankarakoc/Desktop/CrossBall-AppStore-Marketing")

# Brand palette
BG_DEEP = (8, 22, 16)
BG_MID = (18, 48, 34)
BG_LIGHT = (28, 72, 48)
LIME = (195, 244, 0)
LIME_SOFT = (184, 242, 74)
GOLD = (233, 195, 73)
WHITE = (244, 247, 242)
MUTED = (168, 181, 168)
CARD_EDGE = (40, 70, 55)

# Slide order for App Store (first 3 appear on install sheet)
SLIDES = [
    {
        "file": "01_daily_puzzle.png",
        "out": "01_connect_the_clubs.png",
        "headline": "Connect the Clubs",
        "sub": "Name players who played for both clubs\non a daily 3×3 football grid.",
        "badge": "DAILY PUZZLE",
    },
    {
        "file": "02_home.png",
        "out": "02_one_puzzle_every_day.png",
        "headline": "One Puzzle.\nEvery Day.",
        "sub": "Build your streak. Fresh clubs at\nmidnight UTC — one shared challenge.",
        "badge": "RITUAL",
    },
    {
        "file": "03_leaderboard.png",
        "out": "03_prove_your_iq.png",
        "headline": "Prove Your\nFootball IQ",
        "sub": "Rare picks score higher. Climb the\nweekly board. Outsmart the obvious.",
        "badge": "COMPETE",
    },
    {
        "file": "04_community.png",
        "out": "04_play_with_friends.png",
        "headline": "Play With\nFriends",
        "sub": "Async challenges, daily missions,\nand community goals — together.",
        "badge": "SOCIAL",
    },
    {
        "file": "05_premium.png",
        "out": "05_go_premium.png",
        "headline": "Train Harder.\nGo Premium.",
        "sub": "Unlimited practice, ad-free hints,\nand more modes when you're ready.",
        "badge": "PREMIUM",
    },
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    paths = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                continue
    return ImageFont.load_default()


def gradient_bg(size: tuple[int, int], accent_shift: float = 0.0) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        # Vertical deep pitch gradient
        r = int(BG_DEEP[0] * (1 - t) + BG_MID[0] * t)
        g = int(BG_DEEP[1] * (1 - t) + BG_MID[1] * t)
        b = int(BG_DEEP[2] * (1 - t) + BG_MID[2] * t)
        for x in range(w):
            # Soft diagonal lime wash
            d = (x / w + t * 0.35 + accent_shift) % 1.0
            boost = max(0.0, 1.0 - abs(d - 0.42) * 4.5) * 0.18
            px[x, y] = (
                min(255, int(r + LIME[0] * boost * 0.25)),
                min(255, int(g + LIME[1] * boost * 0.35)),
                min(255, int(b + LIME[2] * boost * 0.15)),
            )
    return img


def draw_diagonal_panels(draw: ImageDraw.ImageDraw, size: tuple[int, int], variant: int):
    w, h = size
    # Large slanted brand panels (template-like continuity)
    offsets = [
        (-0.15 + variant * 0.04, 0.55),
        (0.35 + variant * 0.03, 0.92),
    ]
    colors = [
        (*LIME, 38),
        (*BG_LIGHT, 90),
    ]
    for (x0r, y0r), color in zip(offsets, colors):
        x0 = int(w * x0r)
        y0 = int(h * y0r)
        pts = [
            (x0, y0),
            (x0 + int(w * 0.85), y0 - int(h * 0.18)),
            (x0 + int(w * 0.95), y0 + int(h * 0.12)),
            (x0 + int(w * 0.1), y0 + int(h * 0.28)),
        ]
        overlay = Image.new("RGBA", size, (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.polygon(pts, fill=color)
        # We'll composite later — return overlays via draw on RGBA canvas instead
        draw.bitmap  # noqa — placeholder to keep signature


def make_panel_overlay(size: tuple[int, int], variant: int) -> Image.Image:
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    w, h = size
    # Top lime slash
    y1 = int(h * (0.08 + variant * 0.01))
    od.polygon(
        [
            (0, y1),
            (w, y1 - int(h * 0.06)),
            (w, y1 + int(h * 0.10)),
            (0, y1 + int(h * 0.16)),
        ],
        fill=(*LIME, 28),
    )
    # Bottom deep panel
    y2 = int(h * 0.72)
    od.polygon(
        [
            (0, y2),
            (w, y2 - int(h * 0.08)),
            (w, h),
            (0, h),
        ],
        fill=(*BG_DEEP, 140),
    )
    # Accent bar
    od.rectangle((0, int(h * 0.0), int(w * 0.012), h), fill=(*LIME, 200))
    return overlay


def round_corners(im: Image.Image, radius: int) -> Image.Image:
    im = im.convert("RGBA")
    mask = Image.new("L", im.size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, im.width, im.height), radius=radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0))
    out.putalpha(mask)
    return out


def device_frame(screenshot: Image.Image, frame_w: int, frame_h: int, radius: int) -> Image.Image:
    """Fit screenshot into a dark device bezel."""
    bezel = 18
    inner_w = frame_w - bezel * 2
    inner_h = frame_h - bezel * 2

    # Cover-fit screenshot into inner area
    src = screenshot.convert("RGBA")
    scale = max(inner_w / src.width, inner_h / src.height)
    nw, nh = int(src.width * scale), int(src.height * scale)
    src = src.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - inner_w) // 2
    top = (nh - inner_h) // 2
    src = src.crop((left, top, left + inner_w, top + inner_h))
    src = round_corners(src, radius - 8)

    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    # Outer bezel
    fd.rounded_rectangle((0, 0, frame_w - 1, frame_h - 1), radius=radius, fill=(12, 18, 14, 255))
    # Inner rim
    fd.rounded_rectangle(
        (4, 4, frame_w - 5, frame_h - 5),
        radius=radius - 4,
        outline=(*LIME, 90),
        width=2,
    )
    frame.paste(src, (bezel, bezel), src)

    # Soft shadow
    shadow = Image.new("RGBA", (frame_w + 40, frame_h + 40), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((20, 24, 20 + frame_w, 24 + frame_h), radius=radius, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    composed = Image.new("RGBA", (frame_w + 40, frame_h + 40), (0, 0, 0, 0))
    composed.alpha_composite(shadow, (0, 0))
    composed.alpha_composite(frame, (20, 16))
    return composed


def wrap_lines(text: str, fnt, max_width: int) -> list[str]:
    lines: list[str] = []
    for raw in text.split("\n"):
        words = raw.split()
        if not words:
            lines.append("")
            continue
        cur: list[str] = []
        for w in words:
            trial = " ".join(cur + [w])
            if fnt.getlength(trial) <= max_width:
                cur.append(w)
            else:
                if cur:
                    lines.append(" ".join(cur))
                cur = [w]
        if cur:
            lines.append(" ".join(cur))
    return lines


def render_slide(
    screenshot_path: Path,
    size: tuple[int, int],
    slide: dict,
    index: int,
    is_ipad: bool,
) -> Image.Image:
    w, h = size
    base = gradient_bg(size, accent_shift=index * 0.08).convert("RGBA")
    panels = make_panel_overlay(size, index)
    base = Image.alpha_composite(base, panels)
    draw = ImageDraw.Draw(base)

    pad_x = int(w * 0.07)
    # Badge
    badge_font = font(int(w * 0.028), bold=True)
    badge = slide["badge"]
    bw = int(badge_font.getlength(badge) + w * 0.04)
    bh = int(h * 0.028)
    bx, by = pad_x, int(h * 0.055)
    draw.rounded_rectangle((bx, by, bx + bw, by + bh), radius=bh // 2, fill=(*LIME, 230))
    draw.text((bx + (bw - badge_font.getlength(badge)) / 2, by + bh * 0.18), badge, font=badge_font, fill=BG_DEEP)

    # Headline
    h_font = font(int(w * (0.078 if not is_ipad else 0.062)), bold=True)
    s_font = font(int(w * (0.036 if not is_ipad else 0.030)))
    y = by + bh + int(h * 0.025)
    max_text_w = int(w * 0.86)
    for line in wrap_lines(slide["headline"], h_font, max_text_w):
        draw.text((pad_x, y), line, font=h_font, fill=WHITE)
        y += int(h_font.size * 1.12)

    y += int(h * 0.012)
    for line in wrap_lines(slide["sub"], s_font, max_text_w):
        draw.text((pad_x, y), line, font=s_font, fill=MUTED)
        y += int(s_font.size * 1.35)

    # Device mockup area
    shot = Image.open(screenshot_path)
    if is_ipad:
        frame_w = int(w * 0.72)
        frame_h = int(h * 0.58)
        radius = 36
    else:
        frame_w = int(w * 0.78)
        frame_h = int(h * 0.62)
        radius = 52

    device = device_frame(shot, frame_w, frame_h, radius)
    # Slight scale if device larger than remaining space
    max_dev_h = h - y - int(h * 0.06)
    max_dev_w = w - pad_x * 2
    scale = min(1.0, max_dev_w / device.width, max_dev_h / device.height)
    if scale < 1.0:
        device = device.resize((int(device.width * scale), int(device.height * scale)), Image.Resampling.LANCZOS)

    dx = (w - device.width) // 2
    dy = y + int(h * 0.02)
    # Keep bottom margin
    if dy + device.height > h - int(h * 0.04):
        dy = h - int(h * 0.04) - device.height

    base.alpha_composite(device, (dx, dy))

    # Brand footer
    brand = font(int(w * 0.028), bold=True)
    draw.text((pad_x, h - int(h * 0.035)), "CrossBall", font=brand, fill=LIME)

    return base.convert("RGB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    iphone_dir = OUT / "iPhone-6.5-inch"
    ipad_dir = OUT / "iPad-13-inch"
    iphone_dir.mkdir(exist_ok=True)
    ipad_dir.mkdir(exist_ok=True)

    print("Generating professional App Store marketing screenshots…")
    for i, slide in enumerate(SLIDES):
        src_i = SRC_IPHONE / slide["file"]
        src_p = SRC_IPAD / slide["file"]
        if not src_i.exists():
            raise SystemExit(f"Missing iPhone source: {src_i}")
        if not src_p.exists():
            raise SystemExit(f"Missing iPad source: {src_p}")

        out_i = iphone_dir / slide["out"]
        out_p = ipad_dir / slide["out"]
        render_slide(src_i, IPHONE_SIZE, slide, i, False).save(out_i, "PNG", optimize=True)
        print(f"  ✓ iPhone {slide['out']} {IPHONE_SIZE[0]}×{IPHONE_SIZE[1]}")
        render_slide(src_p, IPAD_SIZE, slide, i, True).save(out_p, "PNG", optimize=True)
        print(f"  ✓ iPad   {slide['out']} {IPAD_SIZE[0]}×{IPAD_SIZE[1]}")

    readme = OUT / "README.txt"
    readme.write_text(
        """CrossBall — Professional App Store Marketing Screenshots
=======================================================

App Store Connect upload:

iPhone tab → 6.5" Display
  Folder: iPhone-6.5-inch/
  Size:   1284 × 2778 (accepted)
  Order:  01 → 05 (first 3 show on install sheet)

iPad tab → 13" Display
  Folder: iPad-13-inch/
  Size:   2048 × 2732 (accepted)
  Order:  01 → 05

Copy:
  01 Connect the Clubs — daily grid mechanic
  02 One Puzzle. Every Day. — streak / ritual
  03 Prove Your Football IQ — rarity + weekly board
  04 Play With Friends — community / challenges
  05 Train Harder. Go Premium. — monetization

Sources: real Simulator captures (iPhone 17 Pro Max + iPad Pro 13").
""",
        encoding="utf-8",
    )
    print(f"\nDone → {OUT}")


if __name__ == "__main__":
    main()
