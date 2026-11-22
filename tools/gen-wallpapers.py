#!/usr/bin/env python3
"""Uhuru OS v19.1: huzalisha wallpapers 5 za Kitanzania (kazi ASILI ya Letema Group Tech).

Hakuna picha ya mtu mwingine iliyotumika: kila kitu kinachorwa kwa msimbo huu (Pillow + numpy).
Kwa hiyo leseni ni yetu (angalia docs/LICENSE-WALLPAPERS.md). Matokeo ni yale yale kila ukiendesha (seed thabiti).

Matumizi (kwa wasanidi tu, si sehemu ya ISO):
    python3 tools/gen-wallpapers.py [folda-ya-matokeo]
Chaguo-msingi: config/includes.chroot/usr/share/backgrounds/uhuru
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1920, 1080
S = 2                       # supersample (kuchora kubwa kisha kupunguza = kingo laini)
BW, BH = W * S, H * S
OUT_DEFAULT = os.path.join("config", "includes.chroot", "usr", "share", "backgrounds", "uhuru")


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def vgrad(stops, w=BW, h=BH):
    """Gradient ya wima: stops = [(nafasi 0..1, '#rrggbb'), ...]."""
    ys = np.linspace(0, 1, h)
    pos = [p for p, _ in stops]
    cols = np.array([hexrgb(c) for _, c in stops], dtype=float)
    ch = [np.interp(ys, pos, cols[:, i]) for i in range(3)]
    col = np.stack(ch, axis=1)                       # h x 3
    arr = np.repeat(col[:, None, :], w, axis=1)      # h x w x 3
    return Image.fromarray(arr.astype(np.uint8), "RGB")


def glow(img, cx, cy, radius, color, strength=1.0):
    """Mwanga wa duara (radial) unaochanganywa juu ya picha."""
    yy, xx = np.mgrid[0:img.height, 0:img.width]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / radius
    a = np.clip(1 - d, 0, 1) ** 2 * strength
    base = np.asarray(img, dtype=float)
    c = np.array(hexrgb(color), dtype=float)
    out = base * (1 - a[..., None]) + c * a[..., None]
    return Image.fromarray(out.astype(np.uint8), "RGB")


def ridge(rng, n, base, amp, rough=0.55, seed_pts=6):
    """Mstari wa milima (midpoint displacement) wenye n pointi."""
    pts = [rng.uniform(-1, 1) for _ in range(seed_pts)]
    size = seed_pts
    scale = 1.0
    while size < n:
        new = []
        for i in range(len(pts) - 1):
            new.append(pts[i])
            new.append((pts[i] + pts[i + 1]) / 2 + rng.uniform(-1, 1) * scale)
        new.append(pts[-1])
        pts = new
        size = len(pts)
        scale *= rough
    arr = np.array(pts[:n]) if len(pts) >= n else np.interp(np.linspace(0, len(pts) - 1, n), range(len(pts)), pts)
    arr = np.interp(np.linspace(0, len(pts) - 1, n), range(len(pts)), pts)
    arr = (arr - arr.min()) / max(1e-9, arr.max() - arr.min())
    return base - arr * amp


def fill_below(draw, ys, color, step=1):
    n = len(ys)
    poly = [(i * BW / (n - 1), ys[i]) for i in range(0, n, step)]
    poly += [(BW, BH), (0, BH)]
    draw.polygon(poly, fill=color)


def acacia(draw, x, y, scale, color):
    """Mti wa mkuyu/mbuyu wa Serengeti (kivuli): shina + kuba tambarare."""
    t = scale
    draw.polygon([(x - 6 * t, y), (x - 3 * t, y - 120 * t), (x + 3 * t, y - 120 * t), (x + 6 * t, y)], fill=color)
    draw.polygon([(x, y - 110 * t), (x - 70 * t, y - 150 * t), (x - 60 * t, y - 135 * t)], fill=color)
    draw.polygon([(x, y - 100 * t), (x + 70 * t, y - 145 * t), (x + 58 * t, y - 128 * t)], fill=color)
    draw.ellipse([x - 150 * t, y - 190 * t, x + 150 * t, y - 130 * t], fill=color)
    draw.ellipse([x - 100 * t, y - 215 * t, x + 105 * t, y - 155 * t], fill=color)
    draw.ellipse([x - 60 * t, y - 235 * t, x + 70 * t, y - 180 * t], fill=color)


def bird(draw, x, y, size, color, width):
    """Ndege mdogo angani (herufi V iliyopinda)."""
    draw.arc([x - size, y - size / 2, x, y + size / 2], 200, 340, fill=color, width=width)
    draw.arc([x, y - size / 2, x + size, y + size / 2], 200, 340, fill=color, width=width)


def finish(img, vignette=0.0):
    img = img.resize((W, H), Image.LANCZOS)
    if vignette > 0:
        yy, xx = np.mgrid[0:H, 0:W]
        d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2) / math.sqrt(2)
        a = np.clip(d, 0, 1) ** 2 * vignette
        arr = np.asarray(img, dtype=float) * (1 - a[..., None])
        img = Image.fromarray(arr.astype(np.uint8), "RGB")
    return img


# ----------------------------------------------------------------------------- 1. Kilimanjaro
def kilimanjaro():
    rng = random.Random(1961)
    img = vgrad([(0, "#171f4d"), (0.35, "#4b3a7a"), (0.58, "#e0705a"), (0.74, "#ffb15c"), (1, "#ffe7a8")])
    img = glow(img, BW * 0.68, BH * 0.66, BW * 0.55, "#ffd27a", 0.75)
    d = ImageDraw.Draw(img, "RGBA")
    # nyota hafifu juu
    for _ in range(90):
        x, y = rng.uniform(0, BW), rng.uniform(0, BH * 0.28)
        r = rng.choice([1, 1, 2]) * S
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, rng.randint(60, 170)))
    # jua
    d.ellipse([BW * 0.68 - 70 * S, BH * 0.665 - 70 * S, BW * 0.68 + 70 * S, BH * 0.665 + 70 * S], fill=(255, 236, 170, 235))
    # Kibo (kilele kipana chenye theluji) na Mawenzi (kilele chenye meno)
    kx0, kx1, base = BW * 0.30, BW * 0.92, BH * 0.78
    kib = [(kx0, base), (kx0 + (kx1 - kx0) * 0.10, BH * 0.585), (kx0 + (kx1 - kx0) * 0.30, BH * 0.46),
           (kx0 + (kx1 - kx0) * 0.46, BH * 0.425), (kx0 + (kx1 - kx0) * 0.62, BH * 0.43),
           (kx0 + (kx1 - kx0) * 0.80, BH * 0.50), (kx1, base)]
    d.polygon(kib, fill=(78, 66, 118, 255))
    # upande wa kivuli
    d.polygon([kib[3], kib[4], kib[5], kib[6], (kx0 + (kx1 - kx0) * 0.5, base)], fill=(58, 48, 96, 255))
    # theluji
    snow = [(kx0 + (kx1 - kx0) * 0.20, BH * 0.505), (kx0 + (kx1 - kx0) * 0.26, BH * 0.475),
            (kx0 + (kx1 - kx0) * 0.30, BH * 0.46), (kx0 + (kx1 - kx0) * 0.46, BH * 0.425),
            (kx0 + (kx1 - kx0) * 0.62, BH * 0.43), (kx0 + (kx1 - kx0) * 0.72, BH * 0.462),
            (kx0 + (kx1 - kx0) * 0.66, BH * 0.472), (kx0 + (kx1 - kx0) * 0.60, BH * 0.455),
            (kx0 + (kx1 - kx0) * 0.55, BH * 0.482), (kx0 + (kx1 - kx0) * 0.48, BH * 0.458),
            (kx0 + (kx1 - kx0) * 0.42, BH * 0.49), (kx0 + (kx1 - kx0) * 0.36, BH * 0.47),
            (kx0 + (kx1 - kx0) * 0.30, BH * 0.505), (kx0 + (kx1 - kx0) * 0.25, BH * 0.49)]
    d.polygon(snow, fill=(250, 244, 240, 255))
    d.polygon([snow[3], snow[4], snow[5], (kx0 + (kx1 - kx0) * 0.58, BH * 0.45)], fill=(255, 214, 190, 235))
    mx = BW * 0.17
    maw = [(0, BH * 0.80), (mx * 0.45, BH * 0.62), (mx * 0.85, BH * 0.55), (mx * 1.0, BH * 0.60), (mx * 1.15, BH * 0.52),
           (mx * 1.45, BH * 0.60), (mx * 1.7, BH * 0.70), (mx * 2.1, BH * 0.80)]
    d.polygon(maw, fill=(94, 76, 128, 255))
    # tabaka za vilima (nyuma -> mbele), kila moja nyeusi zaidi
    layers = [(0.80, 60, "#6c4f86"), (0.84, 70, "#4d3b6e"), (0.89, 80, "#2f2d58"), (0.95, 70, "#1b2146")]
    for base_f, amp, col in layers:
        ys = ridge(rng, 900, BH * base_f, amp * S)
        fill_below(d, ys, hexrgb(col) + (255,), step=3)
    # ukungu mwanga chini ya mlima
    haze = Image.new("RGBA", img.size, (255, 200, 140, 0))
    hd = ImageDraw.Draw(haze)
    for i in range(40):
        a = int(70 * (1 - i / 40))
        hd.rectangle([0, BH * 0.78 - i * 3 * S, BW, BH * 0.78 - (i - 1) * 3 * S], fill=(255, 205, 150, a))
    img = Image.alpha_composite(img.convert("RGBA"), haze.filter(ImageFilter.GaussianBlur(6 * S)))
    d = ImageDraw.Draw(img, "RGBA")
    acacia(d, BW * 0.09, BH * 0.975, 1.35 * S, (14, 16, 38, 255))
    acacia(d, BW * 0.94, BH * 0.99, 0.95 * S, (14, 16, 38, 255))
    for (bx, by, sz) in [(0.56, 0.30, 26), (0.60, 0.27, 20), (0.52, 0.33, 18), (0.64, 0.33, 16)]:
        bird(d, BW * bx, BH * by, sz * S, (24, 20, 50, 230), 3 * S)
    return finish(img.convert("RGB"))


# ----------------------------------------------------------------------------- 2. Zanzibar
def zanzibar():
    rng = random.Random(1964)
    hz = BH * 0.52
    sky = vgrad([(0, "#14305e"), (0.30, "#3b6fa6"), (0.58, "#e9885a"), (0.80, "#f7b36a"), (1, "#ffd48a")], BW, int(hz))
    sea = vgrad([(0, "#f7b36a"), (0.06, "#2bb7c4"), (0.45, "#0a7d9a"), (1, "#05405e")], BW, int(BH - hz))
    img = Image.new("RGB", (BW, BH))
    img.paste(sky, (0, 0))
    img.paste(sea, (0, int(hz)))
    img = glow(img, BW * 0.30, hz, BW * 0.42, "#ffe2a0", 0.9)
    d = ImageDraw.Draw(img, "RGBA")
    sx = BW * 0.30
    d.ellipse([sx - 80 * S, hz - 80 * S, sx + 80 * S, hz + 80 * S], fill=(255, 244, 205, 245))
    # mawingu membamba
    for _ in range(9):
        cx, cy = rng.uniform(0, BW), rng.uniform(BH * 0.08, BH * 0.38)
        wd, ht = rng.uniform(220, 520) * S, rng.uniform(10, 24) * S
        d.ellipse([cx - wd / 2, cy - ht / 2, cx + wd / 2, cy + ht / 2], fill=(255, 220, 190, rng.randint(40, 90)))
    # mng'ao wa jua juu ya bahari
    for i in range(46):
        y = hz + 6 * S + i * (BH - hz) / 60
        wd = (150 - i * 2.0) * S * (0.5 + 0.5 * rng.random())
        d.rectangle([sx - wd, y, sx + wd, y + 3 * S], fill=(255, 235, 175, int(190 * (1 - i / 50))))
    # mawimbi
    for i in range(60):
        y = hz + rng.uniform(20, BH - hz - 10)
        x = rng.uniform(0, BW)
        wd = rng.uniform(60, 220) * S * (y / BH + 0.3)
        d.line([x, y, x + wd, y], fill=(255, 255, 255, rng.randint(18, 50)), width=2 * S)
    # kisiwa kidogo mbali
    d.ellipse([BW * 0.70, hz - 14 * S, BW * 0.86, hz + 10 * S], fill=(24, 74, 96, 255))
    # jahazi (dhow) na tanga la pembe tatu
    dx, dy = BW * 0.60, BH * 0.675
    hull = [(dx - 170 * S, dy), (dx + 190 * S, dy - 14 * S), (dx + 150 * S, dy + 30 * S), (dx - 120 * S, dy + 34 * S)]
    d.polygon(hull, fill=(20, 24, 40, 255))
    d.polygon([(dx + 190 * S, dy - 14 * S), (dx + 230 * S, dy - 34 * S), (dx + 170 * S, dy + 6 * S)], fill=(20, 24, 40, 255))
    d.line([dx - 10 * S, dy, dx + 40 * S, dy - 300 * S], fill=(20, 24, 40, 255), width=5 * S)
    d.polygon([(dx + 42 * S, dy - 296 * S), (dx - 150 * S, dy - 20 * S), (dx + 170 * S, dy - 22 * S)], fill=(250, 238, 214, 245))
    d.polygon([(dx + 42 * S, dy - 296 * S), (dx + 40 * S, dy - 22 * S), (dx + 170 * S, dy - 22 * S)], fill=(235, 190, 140, 230))
    d.ellipse([dx - 150 * S, dy + 30 * S, dx + 160 * S, dy + 54 * S], fill=(0, 0, 0, 55))
    # ufukwe wa mchanga + mnazi (kulia chini)
    sand = [(BW * 0.58, BH), (BW * 0.72, BH * 0.90), (BW * 0.88, BH * 0.84), (BW, BH * 0.81), (BW, BH)]
    d.polygon(sand, fill=(236, 205, 150, 255))
    d.polygon([(BW * 0.66, BH), (BW * 0.80, BH * 0.93), (BW, BH * 0.88), (BW, BH)], fill=(214, 178, 126, 255))
    for (px, py, ph, lean) in [(0.88, 0.86, 400, -0.20), (0.95, 0.89, 310, 0.12)]:
        x0, y0 = BW * px, BH * py
        x1, y1 = x0 + lean * ph * S, y0 - ph * S
        # shina lenye unene unaopungua
        d.polygon([(x0 - 9 * S, y0), (x1 - 4 * S, y1), (x1 + 4 * S, y1), (x0 + 9 * S, y0)], fill=(26, 20, 30, 255))
        # majani ya mnazi: kila jani ni umbo lililopinda lenye ncha
        for ang in range(-165, 16, 22):
            a = math.radians(ang)
            L = (170 + rng.uniform(-20, 20)) * S
            ex, ey = x1 + math.cos(a) * L, y1 + math.sin(a) * L * 0.5 + 70 * S
            mx, my = x1 + math.cos(a) * L * 0.55, y1 + math.sin(a) * L * 0.55 - 38 * S
            nx, ny = -math.sin(a), math.cos(a)
            w_ = 15 * S
            d.polygon([(x1, y1), (mx + nx * w_, my + ny * w_), (ex, ey), (mx - nx * w_, my - ny * w_)], fill=(24, 36, 34, 255))
        d.ellipse([x1 - 10 * S, y1 - 6 * S, x1 + 10 * S, y1 + 14 * S], fill=(60, 36, 24, 255))
    for (bx, by, sz) in [(0.20, 0.20, 22), (0.26, 0.17, 16), (0.15, 0.24, 14)]:
        bird(d, BW * bx, BH * by, sz * S, (255, 255, 255, 200), 3 * S)
    return finish(img.convert("RGB"))


# ----------------------------------------------------------------------------- 3. Tanzanite
def tanzanite():
    rng = random.Random(1967)
    img = vgrad([(0, "#0b0f3a"), (0.5, "#2a1a7a"), (1, "#0e1c5a")])
    img = glow(img, BW * 0.5, BH * 0.45, BW * 0.65, "#6a4fe0", 0.55)
    d = ImageDraw.Draw(img, "RGBA")
    cols, rows = 16, 9
    cw, ch = BW / cols, BH / rows
    pts = {}
    for r in range(rows + 1):
        for c in range(cols + 1):
            jx = 0 if c in (0, cols) else rng.uniform(-0.38, 0.38) * cw
            jy = 0 if r in (0, rows) else rng.uniform(-0.38, 0.38) * ch
            pts[(r, c)] = (c * cw + jx, r * ch + jy)
    palette = [hexrgb(x) for x in ("#1a2a90", "#3a2fb0", "#5a3fd0", "#7a58e8", "#2d5bd6", "#1d3fa8", "#8a6af0")]
    cx0, cy0 = BW * 0.5, BH * 0.45
    for r in range(rows):
        for c in range(cols):
            a, b, c2, d2 = pts[(r, c)], pts[(r, c + 1)], pts[(r + 1, c + 1)], pts[(r + 1, c)]
            tris = [(a, b, c2), (a, c2, d2)] if rng.random() < 0.5 else [(a, b, d2), (b, c2, d2)]
            for t in tris:
                mx = sum(p[0] for p in t) / 3
                my = sum(p[1] for p in t) / 3
                dist = math.hypot((mx - cx0) / BW, (my - cy0) / BH)
                base = palette[rng.randrange(len(palette))]
                k = 0.55 + 0.85 * (1 - min(1, dist * 1.5)) + rng.uniform(-0.18, 0.18)
                col = tuple(int(min(255, max(0, v * k))) for v in base)
                d.polygon(t, fill=col + (150,), outline=(190, 170, 255, 70))
    # mwangaza wa kito katikati
    hl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    for i in range(18):
        s = 1 - i / 18
        hd.polygon([(cx0, cy0 - 330 * S * s), (cx0 + 270 * S * s, cy0), (cx0, cy0 + 330 * S * s), (cx0 - 270 * S * s, cy0)],
                   fill=(210, 200, 255, int(10 + 9 * s)))
    img = Image.alpha_composite(img.convert("RGBA"), hl.filter(ImageFilter.GaussianBlur(2 * S)))
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(140):
        x, y = rng.uniform(0, BW), rng.uniform(0, BH)
        rr = rng.choice([1, 1, 2, 3]) * S
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(235, 230, 255, rng.randint(40, 150)))
    return finish(img.convert("RGB"), vignette=0.35)


# ----------------------------------------------------------------------------- 4. Kitenge
def kitenge():
    rng = random.Random(1971)
    GREEN, YELLOW, BLUE, BLACK = "#1eb53a", "#fcd116", "#00a3dd", "#101418"
    ORANGE, RED, CREAM = "#f26b21", "#d7263d", "#fff4d6"
    img = Image.new("RGB", (BW, BH), hexrgb("#0e5a46"))
    d = ImageDraw.Draw(img, "RGBA")
    cell = 270 * S
    for r in range(-1, int(BH / cell) + 2):
        for c in range(-1, int(BW / cell) + 2):
            cx, cy = c * cell + cell / 2, r * cell + cell / 2
            bg = [GREEN, "#0e8a4a", "#0e5a46"][(r + c) % 3]
            d.rectangle([c * cell, r * cell, (c + 1) * cell, (r + 1) * cell], fill=hexrgb(bg))
            style = (r * 3 + c * 5) % 4
            if style == 0:       # duara za ndani ndani
                for i, col in enumerate([YELLOW, BLACK, ORANGE, CREAM, BLUE]):
                    rad = (118 - i * 22) * S
                    d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=hexrgb(col))
            elif style == 1:     # almasi
                for i, col in enumerate([BLUE, YELLOW, BLACK, RED]):
                    s = (122 - i * 28) * S
                    d.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)], fill=hexrgb(col))
            elif style == 2:     # ua la petali
                for k in range(8):
                    a = math.radians(k * 45)
                    px, py = cx + math.cos(a) * 58 * S, cy + math.sin(a) * 58 * S
                    d.ellipse([px - 34 * S, py - 34 * S, px + 34 * S, py + 34 * S], fill=hexrgb(YELLOW if k % 2 else ORANGE))
                d.ellipse([cx - 40 * S, cy - 40 * S, cx + 40 * S, cy + 40 * S], fill=hexrgb(BLACK))
                d.ellipse([cx - 22 * S, cy - 22 * S, cx + 22 * S, cy + 22 * S], fill=hexrgb(CREAM))
            else:                # zigzag
                for k in range(-2, 3):
                    y0 = cy + k * 40 * S
                    zz = [(cx - 125 * S + i * 25 * S, y0 + (14 * S if i % 2 else -14 * S)) for i in range(11)]
                    d.line(zz, fill=hexrgb([YELLOW, BLUE, CREAM, ORANGE, BLACK][k + 2]), width=10 * S)
            # alama ndogo za wax-print kwenye pembe
            for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                px, py = cx + dx * 128 * S, cy + dy * 128 * S
                d.ellipse([px - 7 * S, py - 7 * S, px + 7 * S, py + 7 * S], fill=hexrgb(CREAM))
    # kivuli cheusi juu ili ikoni na maandishi visomeke
    img = img.convert("RGBA")
    shade = vgrad([(0, "#000000"), (1, "#000000")]).convert("RGBA")
    yy, xx = np.mgrid[0:BH, 0:BW]
    dist = np.sqrt(((xx - BW * 0.5) / (BW * 0.5)) ** 2 + ((yy - BH * 0.5) / (BH * 0.5)) ** 2) / math.sqrt(2)
    alpha = (np.clip(0.50 - 0.20 * (dist ** 1.5) * 1.6, 0.30, 0.55) * 255).astype(np.uint8)
    shade.putalpha(Image.fromarray(alpha, "L"))
    img = Image.alpha_composite(img, shade)
    return finish(img.convert("RGB"))


# ----------------------------------------------------------------------------- 5. Tingatinga (mtindo)
def tingatinga():
    rng = random.Random(1968)
    img = Image.new("RGB", (BW, BH), hexrgb("#0a7fb0"))
    d = ImageDraw.Draw(img, "RGBA")
    INK = (18, 14, 22, 255)
    lw = 5 * S
    # mandhari ya rangi moja inayong'aa na mapambo ya mviringo
    for _ in range(22):
        cx, cy, rr = rng.uniform(0, BW), rng.uniform(0, BH), rng.uniform(40, 110) * S
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(255, 255, 255, 14))
    # jua kubwa lenye miale
    sx, sy, sr = BW * 0.74, BH * 0.28, 140 * S
    for k in range(24):
        a = math.radians(k * 15)
        a2 = math.radians(k * 15 + 7)
        r1, r2 = sr * 1.12, sr * (1.75 if k % 2 == 0 else 1.5)
        d.polygon([(sx + math.cos(a) * r1, sy + math.sin(a) * r1), (sx + math.cos((a + a2) / 2) * r2, sy + math.sin((a + a2) / 2) * r2),
                   (sx + math.cos(a2) * r1, sy + math.sin(a2) * r1)], fill=(255, 196, 36, 255), outline=INK)
    d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 214, 51, 255), outline=INK, width=lw)
    d.ellipse([sx - sr * 0.66, sy - sr * 0.66, sx + sr * 0.66, sy + sr * 0.66], fill=(255, 150, 40, 255), outline=INK, width=lw)
    # ardhi ya kijani chini
    d.polygon([(0, BH * 0.83), (BW * 0.3, BH * 0.78), (BW * 0.62, BH * 0.84), (BW, BH * 0.79), (BW, BH), (0, BH)],
              fill=(40, 160, 70, 255), outline=INK)
    d.polygon([(0, BH * 0.93), (BW * 0.4, BH * 0.89), (BW, BH * 0.95), (BW, BH), (0, BH)], fill=(24, 120, 56, 255), outline=INK)
    # majani makubwa pande zote
    def leaf(x, y, L, W_, ang, col):
        a = math.radians(ang)
        ca, sa = math.cos(a), math.sin(a)
        pts = []
        for t in np.linspace(0, 1, 18):
            w = math.sin(math.pi * t) * W_
            pts.append((x + ca * L * t - sa * w, y + sa * L * t + ca * w))
        for t in np.linspace(1, 0, 18):
            w = math.sin(math.pi * t) * W_
            pts.append((x + ca * L * t + sa * w, y + sa * L * t - ca * w))
        d.polygon(pts, fill=col, outline=INK)
        d.line([x, y, x + ca * L, y + sa * L], fill=INK, width=3 * S)
    for (x, y, L, w_, a, col) in [
        (BW * 0.04, BH * 0.86, 330 * S, 52 * S, -62, (30, 170, 80, 255)),
        (BW * 0.04, BH * 0.86, 290 * S, 46 * S, -28, (60, 200, 100, 255)),
        (BW * 0.04, BH * 0.86, 260 * S, 44 * S, -95, (20, 140, 70, 255)),
        (BW * 0.96, BH * 0.88, 340 * S, 52 * S, -118, (30, 170, 80, 255)),
        (BW * 0.96, BH * 0.88, 280 * S, 46 * S, -152, (60, 200, 100, 255)),
        (BW * 0.96, BH * 0.88, 250 * S, 44 * S, -85, (20, 140, 70, 255)),
    ]:
        leaf(x, y, L, w_, a, col)
    # maua
    def flower(x, y, R, c1, c2):
        for k in range(8):
            a = math.radians(k * 45)
            px, py = x + math.cos(a) * R, y + math.sin(a) * R
            d.ellipse([px - R * 0.62, py - R * 0.62, px + R * 0.62, py + R * 0.62], fill=c1, outline=INK, width=3 * S)
        d.ellipse([x - R * 0.7, y - R * 0.7, x + R * 0.7, y + R * 0.7], fill=c2, outline=INK, width=3 * S)
    flower(BW * 0.17, BH * 0.60, 38 * S, (244, 60, 120, 255), (255, 230, 70, 255))
    flower(BW * 0.09, BH * 0.46, 28 * S, (255, 140, 40, 255), (255, 250, 220, 255))
    flower(BW * 0.88, BH * 0.62, 36 * S, (180, 70, 220, 255), (255, 230, 70, 255))
    flower(BW * 0.94, BH * 0.45, 26 * S, (244, 60, 120, 255), (255, 250, 220, 255))
    # ndege mkubwa wa mtindo (korongo mwenye taji): mwili, shingo, kichwa, mdomo, mkia wa manyoya
    bx, by = BW * 0.40, BH * 0.64
    d.ellipse([bx - 190 * S, by - 150 * S, bx + 190 * S, by + 80 * S], fill=(58, 70, 100, 255), outline=INK, width=lw)
    d.ellipse([bx - 120 * S, by - 110 * S, bx + 90 * S, by + 40 * S], fill=(86, 104, 150, 255), outline=INK, width=4 * S)
    for k in range(4):
        d.arc([bx - 100 * S + k * 8 * S, by - 90 * S + k * 20 * S, bx + 70 * S - k * 8 * S, by + 30 * S + k * 6 * S], 20, 160, fill=INK, width=3 * S)
    for k, col in enumerate([(244, 60, 120, 255), (255, 150, 40, 255), (255, 230, 70, 255), (40, 170, 90, 255), (0, 163, 221, 255)]):
        a = math.radians(200 + k * 14)
        ex, ey = bx - 150 * S + math.cos(a) * 330 * S, by + 10 * S + math.sin(a) * 200 * S + 60 * S
        d.polygon([(bx - 130 * S, by - 20 * S), (ex, ey - 28 * S), (ex - 24 * S, ey + 30 * S), (bx - 120 * S, by + 24 * S)], fill=col, outline=INK)
    d.polygon([(bx + 90 * S, by - 130 * S), (bx + 150 * S, by - 300 * S), (bx + 188 * S, by - 290 * S), (bx + 150 * S, by - 120 * S)],
              fill=(235, 235, 240, 255), outline=INK)
    d.ellipse([bx + 120 * S, by - 345 * S, bx + 220 * S, by - 270 * S], fill=(235, 235, 240, 255), outline=INK, width=lw)
    d.polygon([(bx + 214 * S, by - 318 * S), (bx + 300 * S, by - 296 * S), (bx + 216 * S, by - 290 * S)], fill=(255, 150, 40, 255), outline=INK)
    d.ellipse([bx + 168 * S, by - 322 * S, bx + 184 * S, by - 306 * S], fill=INK)
    for k in range(5):
        a = math.radians(-120 + k * 28)
        hx, hy = bx + 160 * S, by - 340 * S
        d.line([hx, hy, hx + math.cos(a) * 60 * S, hy + math.sin(a) * 60 * S], fill=(255, 214, 51, 255), width=6 * S)
    d.line([bx - 20 * S, by + 60 * S, bx - 30 * S, by + 200 * S], fill=INK, width=8 * S)
    d.line([bx + 40 * S, by + 60 * S, bx + 60 * S, by + 200 * S], fill=INK, width=8 * S)
    return finish(img.convert("RGB"), vignette=0.25)


ARTS = {
    "kilimanjaro": kilimanjaro,
    "zanzibar": zanzibar,
    "tanzanite": tanzanite,
    "kitenge": kitenge,
    "tingatinga": tingatinga,
}

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else OUT_DEFAULT
    os.makedirs(out, exist_ok=True)
    for name, fn in ARTS.items():
        path = os.path.join(out, name + ".png")
        im = fn()
        assert im.size == (W, H)
        im.save(path, optimize=True)
        print("%-12s %4d KB  %s" % (name, os.path.getsize(path) // 1024, path))
