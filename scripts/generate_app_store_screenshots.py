#!/usr/bin/env python3
"""Generate CrossBall App Store marketing screenshots (iPhone + iPad)."""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "app-store-screenshots"

# App Store required sizes
IPHONE_SIZE = (1290, 2796)  # 6.7" — scales to other iPhone sizes
IPAD_SIZE = (2048, 2732)  # 12.9" iPad Pro

# CrossBall brand
BG_TOP = (26, 61, 40)
BG_BOTTOM = (11, 31, 20)
LIME = (195, 244, 0)
LIME_DIM = (171, 214, 0)
GREEN = (46, 125, 50)
CARD = (18, 42, 28)
CARD_BORDER = (42, 64, 52)
TEXT = (244, 247, 242)
MUTED = (168, 181, 168)
GOLD = (233, 195, 73)
MYTHIC = (255, 107, 53)
EPIC = (171, 71, 188)


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def _gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    return img


def _rounded(draw: ImageDraw.ImageDraw, box, radius: int, fill, outline=None, width: int = 1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def _wrap_text(text: str, font, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        trial = " ".join(current + [word])
        if font.getlength(trial) <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines or [text]


def _draw_headline(img: Image.Image, title: str, subtitle: str, pad_x: int, top: int):
    draw = ImageDraw.Draw(img)
    title_font = _font(int(img.width * 0.078), bold=True)
    sub_font = _font(int(img.width * 0.038))
    max_w = img.width - pad_x * 2

    y = top
    for line in _wrap_text(title, title_font, max_w):
        draw.text((pad_x, y), line, font=title_font, fill=LIME)
        y += int(title_font.size * 1.15)

    y += int(sub_font.size * 0.35)
    for line in _wrap_text(subtitle, sub_font, max_w):
        draw.text((pad_x, y), line, font=sub_font, fill=MUTED)
        y += int(sub_font.size * 1.35)
    return y


def _device_shell(img: Image.Image, box: tuple[int, int, int, int], is_ipad: bool):
    draw = ImageDraw.Draw(img)
    _rounded(draw, box, 48 if is_ipad else 56, (8, 20, 14), outline=(60, 90, 70), width=3)
    inner = (box[0] + 24, box[1] + 24, box[2] - 24, box[3] - 24)
    _rounded(draw, inner, 36 if is_ipad else 44, CARD, outline=CARD_BORDER, width=2)
    return inner


def _club_badge(draw, cx: int, cy: int, r: int, color: tuple[int, int, int], label: str):
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color, outline=TEXT, width=2)
    font = _font(max(18, r // 2), bold=True)
    tw = font.getlength(label)
    draw.text((cx - tw / 2, cy - font.size / 2), label, font=font, fill=TEXT)


def _draw_grid_mock(draw, box, cell_names: list[str | None]):
    x0, y0, x1, y1 = box
    gap = 12
    cols, rows = 3, 3
    cw = (x1 - x0 - gap * (cols + 1)) / cols
    ch = (y1 - y0 - gap * (rows + 1)) / rows
    idx = 0
    for row in range(rows):
        for col in range(cols):
            cx = x0 + gap + col * (cw + gap)
            cy = y0 + gap + row * (ch + gap)
            cell_box = (cx, cy, cx + cw, cy + ch)
            filled = cell_names[idx] if idx < len(cell_names) else None
            fill = (30, 72, 48) if filled else (22, 52, 36)
            _rounded(draw, cell_box, 16, fill, outline=(LIME_DIM if filled else CARD_BORDER), width=2)
            if filled:
                font = _font(int(min(cw, ch) * 0.22), bold=True)
                tw = font.getlength(filled)
                draw.text(
                    (cx + (cw - tw) / 2, cy + ch / 2 - font.size / 2),
                    filled,
                    font=font,
                    fill=TEXT,
                )
            else:
                font = _font(int(min(cw, ch) * 0.35), bold=True)
                draw.text((cx + cw / 2 - 8, cy + ch / 2 - font.size / 2), "+", font=font, fill=MUTED)
            idx += 1


def slide_connect(img: Image.Image, inner, is_ipad: bool):
    draw = ImageDraw.Draw(img)
    ix0, iy0, ix1, iy1 = inner
    pad = 40
    # Fictional abstract clubs only — App Store metadata must not imply real teams/leagues (4.1a).
    clubs_row = [("NX", (46, 125, 80)), ("OR", (210, 140, 40)), ("VL", (90, 70, 160))]
    clubs_col = [("AQ", (50, 140, 170)), ("CR", (180, 60, 70)), ("SK", (40, 90, 120))]
    badge_r = 36 if not is_ipad else 44
    y_badges = iy0 + pad + 20
    grid_top = y_badges + badge_r * 2 + 80
    grid_left = ix0 + pad + 90
    grid_right = ix1 - pad
    grid_bottom = iy1 - pad - 40

    for i, (lab, col) in enumerate(clubs_row):
        x = grid_left + (grid_right - grid_left) * (i + 0.5) / 3
        _club_badge(draw, int(x), int(y_badges), badge_r, col, lab)
    for i, (lab, col) in enumerate(clubs_col):
        y = grid_top + (grid_bottom - grid_top) * (i + 0.5) / 3
        _club_badge(draw, int(grid_left - 70), int(y), badge_r, col, lab)

    _draw_grid_mock(
        draw,
        (grid_left, grid_top, grid_right, grid_bottom),
        ["A. Rivera", "J. Lee", None, None, "S. Park", None, None, None, None],
    )


def slide_find_link(img: Image.Image, inner, is_ipad: bool):
    draw = ImageDraw.Draw(img)
    ix0, iy0, ix1, iy1 = inner
    modal = (ix0 + 40, iy0 + 120, ix1 - 40, iy1 - 80)
    _rounded(draw, modal, 28, (14, 36, 24), outline=LIME_DIM, width=2)

    font_title = _font(42 if not is_ipad else 52, bold=True)
    draw.text((modal[0] + 32, modal[1] + 28), "Search player", font=font_title, fill=TEXT)

    note_font = _font(24 if not is_ipad else 30)
    draw.text((modal[0] + 32, modal[1] + 90), "Possible answer", font=_font(26, bold=True), fill=LIME)
    draw.text(
        (modal[0] + 32, modal[1] + 130),
        "Hints describe one possible answer —",
        font=note_font,
        fill=MUTED,
    )
    draw.text(
        (modal[0] + 32, modal[1] + 162),
        "other correct players still count.",
        font=note_font,
        fill=MUTED,
    )

    chips = [("Nationality", "—"), ("Position", "MF"), ("First letter", "A _ _ _")]
    cx = modal[0] + 32
    cy = modal[1] + 220
    chip_font = _font(22 if not is_ipad else 26)
    for label, value in chips:
        text = f"{label}: {value}"
        tw = chip_font.getlength(text) + 40
        _rounded(draw, (cx, cy, cx + tw, cy + 52), 20, CARD, outline=CARD_BORDER)
        draw.text((cx + 20, cy + 14), text, font=chip_font, fill=TEXT)
        cx += tw + 16
        if cx > modal[2] - 200:
            cx = modal[0] + 32
            cy += 68

    search_box = (modal[0] + 32, modal[1] + 380, modal[2] - 32, modal[1] + 460)
    _rounded(draw, search_box, 22, (22, 52, 36), outline=LIME, width=2)
    draw.text((search_box[0] + 24, search_box[1] + 22), "alex", font=_font(36), fill=TEXT)

    # Fictional names only — do not show real footballers in store metadata.
    results = ["Alex Rivera", "Alex Morgan-Lee", "Alex Quinn"]
    ry = search_box[3] + 24
    for name in results:
        _rounded(draw, (modal[0] + 32, ry, modal[2] - 32, ry + 64), 16, CARD, outline=CARD_BORDER)
        draw.text((modal[0] + 48, ry + 18), name, font=_font(30), fill=TEXT)
        ry += 76


def slide_prove_iq(img: Image.Image, inner, is_ipad: bool):
    draw = ImageDraw.Draw(img)
    ix0, iy0, ix1, iy1 = inner
    card = (ix0 + 50, iy0 + 140, ix1 - 50, iy1 - 100)
    _rounded(draw, card, 32, CARD, outline=GOLD, width=3)

    draw.text((card[0] + 40, card[1] + 36), "Puzzle Complete", font=_font(38, bold=True), fill=TEXT)
    score_font = _font(96 if not is_ipad else 120, bold=True)
    draw.text((card[0] + 40, card[1] + 110), "2,840", font=score_font, fill=LIME)
    draw.text((card[0] + 40, card[1] + 220), "Total score", font=_font(28), fill=MUTED)

    stats_y = card[1] + 300
    for label, val in [("Hints", "2"), ("Mistakes", "0"), ("Streak", "12")]:
        _rounded(draw, (card[0] + 40, stats_y, card[0] + 220, stats_y + 80), 18, (22, 52, 36))
        draw.text((card[0] + 56, stats_y + 12), label, font=_font(22), fill=MUTED)
        draw.text((card[0] + 56, stats_y + 38), val, font=_font(32, bold=True), fill=TEXT)
        stats_y += 96

    rarity_y = card[1] + 300
    rx = card[0] + 280
    for tier, color, count in [("Epic", EPIC, "2"), ("Mythic", MYTHIC, "1")]:
        _rounded(draw, (rx, rarity_y, rx + 200, rarity_y + 72), 18, color)
        draw.text((rx + 20, rarity_y + 20), f"{tier} · {count}", font=_font(26, bold=True), fill=TEXT)
        rx += 220


def slide_daily(img: Image.Image, inner, is_ipad: bool):
    draw = ImageDraw.Draw(img)
    ix0, iy0, ix1, iy1 = inner
    hero = (ix0 + 40, iy0 + 100, ix1 - 40, iy0 + 420)
    _rounded(draw, hero, 28, (24, 58, 38), outline=LIME, width=3)
    draw.text((hero[0] + 32, hero[1] + 32), "Daily Challenge", font=_font(34, bold=True), fill=LIME)
    draw.text((hero[0] + 32, hero[1] + 88), "One puzzle per day.", font=_font(28), fill=TEXT)
    draw.text((hero[0] + 32, hero[1] + 128), "Build your streak.", font=_font(28), fill=MUTED)

    badge = (hero[2] - 180, hero[1] + 40, hero[2] - 40, hero[1] + 120)
    _rounded(draw, badge, 24, (40, 90, 50))
    draw.text((badge[0] + 24, badge[1] + 28), "12 day streak", font=_font(24, bold=True), fill=LIME)

    tiles_y = hero[3] + 40
    for label, val, icon_color in [
        ("This week", "1,240 · #8", GREEN),
        ("Level", "7", GOLD),
    ]:
        tile = (ix0 + 40, tiles_y, ix1 - 40, tiles_y + 120)
        if is_ipad:
            w = (ix1 - ix0 - 120) // 2
            tile = (ix0 + 40 + (0 if label == "This week" else w + 40), tiles_y, ix0 + 40 + w + (0 if label == "This week" else w + 40), tiles_y + 120)
        _rounded(draw, tile, 22, CARD, outline=CARD_BORDER)
        draw.text((tile[0] + 28, tile[1] + 24), label, font=_font(24), fill=MUTED)
        draw.text((tile[0] + 28, tile[1] + 58), val, font=_font(40, bold=True), fill=icon_color)
        if not is_ipad:
            tiles_y += 140

    grid_box = (ix0 + 40, iy1 - 520, ix1 - 40, iy1 - 80)
    _draw_grid_mock(draw, grid_box, [None, None, None, None, None, None, None, None, None])


def slide_leaderboard(img: Image.Image, inner, is_ipad: bool):
    draw = ImageDraw.Draw(img)
    ix0, iy0, ix1, iy1 = inner
    draw.text((ix0 + 40, iy0 + 60), "Weekly Leaderboard", font=_font(36, bold=True), fill=LIME)

    entries = [
        ("1", "mrOk", "3,420"),
        ("2", "GridMaster", "3,180"),
        ("3", "You", "2,840"),
        ("4", "FutbolIQ", "2,610"),
        ("5", "CrossKing", "2,490"),
    ]
    y = iy0 + 140
    for rank, name, score in entries:
        highlight = name == "You"
        box = (ix0 + 36, y, ix1 - 36, y + 72)
        _rounded(
            draw,
            box,
            18,
            (30, 72, 48) if highlight else CARD,
            outline=LIME if highlight else CARD_BORDER,
            width=2 if highlight else 1,
        )
        draw.text((box[0] + 24, y + 20), f"#{rank}", font=_font(28, bold=True), fill=GOLD if rank == "1" else MUTED)
        draw.text((box[0] + 90, y + 20), name, font=_font(30, bold=True), fill=LIME if highlight else TEXT)
        sw = _font(30, bold=True).getlength(score)
        draw.text((box[2] - sw - 24, y + 20), score, font=_font(30, bold=True), fill=TEXT)
        y += 84


SLIDES = [
    ("01_connect_clubs", "Connect the Clubs", "Daily football intersection puzzle", slide_connect),
    ("02_find_the_link", "Find the Link", "Name a player who fits both clubs", slide_find_link),
    ("03_prove_football_iq", "Prove Your Football IQ", "Rare picks score higher than obvious names", slide_prove_iq),
    ("04_daily_challenge", "One Puzzle. Every Day.", "Build your streak · compete weekly", slide_daily),
    ("05_weekly_leaderboard", "Climb the Weekly Board", "Daily scores add up across the week", slide_leaderboard),
]


def render_iap_review_screenshot() -> Path:
    """Required App Review screenshot for submitting crossball_premium IAP."""
    size = IPHONE_SIZE
    img = _gradient(size)
    draw = ImageDraw.Draw(img)
    pad = int(size[0] * 0.1)
    y = int(size[1] * 0.12)

    title = _font(int(size[0] * 0.09), bold=True)
    draw.text((pad, y), "CrossBall Premium", font=title, fill=LIME)
    y += int(title.size * 1.4)
    draw.text((pad, y), "One-time unlock", font=_font(36), fill=MUTED)
    y += 90

    card = (pad, y, size[0] - pad, y + 980)
    _rounded(draw, card, 36, CARD, outline=GOLD, width=3)
    features = [
        "10 ad-free training sessions / day",
        "Advanced stats",
        "Exclusive themes",
        "No ads",
    ]
    fy = card[1] + 60
    for feat in features:
        _rounded(draw, (card[0] + 40, fy, card[2] - 40, fy + 110), 22, (22, 52, 36), outline=CARD_BORDER)
        draw.text((card[0] + 70, fy + 34), feat, font=_font(34, bold=True), fill=TEXT)
        fy += 140

    btn = (pad, card[3] + 80, size[0] - pad, card[3] + 200)
    _rounded(draw, btn, 28, LIME)
    btn_font = _font(40, bold=True)
    label = "Upgrade to Premium"
    tw = btn_font.getlength(label)
    draw.text(((size[0] - tw) / 2, btn[1] + 40), label, font=btn_font, fill=(11, 31, 20))

    draw.text((pad, size[1] - 140), "Product ID: crossball_premium", font=_font(28), fill=MUTED)
    draw.text((pad, size[1] - 90), "Non-Consumable · App Review", font=_font(28), fill=MUTED)

    out = OUT / "iap_review" / "crossball_premium_review.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    return out


def render_slide(
    size: tuple[int, int],
    filename: str,
    title: str,
    subtitle: str,
    painter,
    is_ipad: bool,
) -> Path:
    img = _gradient(size)
    pad_x = int(size[0] * 0.08)
    top = int(size[1] * 0.07)
    content_bottom = _draw_headline(img, title, subtitle, pad_x, top)

    shell_top = content_bottom + int(size[1] * 0.03)
    shell_margin = int(size[0] * 0.06)
    shell_box = (shell_margin, shell_top, size[0] - shell_margin, size[1] - int(size[1] * 0.05))
    inner = _device_shell(img, shell_box, is_ipad)
    painter(img, inner, is_ipad)

    # Watermark
    draw = ImageDraw.Draw(img)
    brand = _font(int(size[0] * 0.032), bold=True)
    draw.text((pad_x, size[1] - int(size[1] * 0.04)), "CrossBall", font=brand, fill=(LIME[0], LIME[1], LIME[2], 180))

    out_dir = OUT / ("ipad" if is_ipad else "iphone")
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{filename}.png"
    img.save(path, "PNG", optimize=True)
    return path


def main():
    print("Generating App Store screenshots…")
    paths: list[Path] = []
    for key, title, sub, painter in SLIDES:
        paths.append(render_slide(IPHONE_SIZE, key, title, sub, painter, False))
        paths.append(render_slide(IPAD_SIZE, key, title, sub, painter, True))
    iap = render_iap_review_screenshot()
    paths.append(iap)
    print(f"Done — {len(paths)} files in {OUT}")
    for p in paths:
        print(f"  {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
