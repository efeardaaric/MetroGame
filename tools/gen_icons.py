#!/usr/bin/env python3
"""Generates the Metro Tycoon: Türkiye app icon set and launch screen.

Design: a red metro "M" sign standing over a sunset Bosphorus skyline (domes,
minarets, a Galata-like tower), with a commuter train crossing a bridge over
the water. Everything is drawn procedurally at 4x and downsampled.

Outputs (assets/icons/):
  icon.png                 1024 master (App Store / iOS, no alpha, no rounded corners)
  icon_192.png             Android legacy launcher
  adaptive_foreground.png  Android adaptive layers (432, sign inside the 66 % safe zone)
  adaptive_background.png
  adaptive_monochrome.png  Android 13 themed icon
  splash.png               iOS launch image (1242x2688)
  ios/AppIcon-*.png        every iOS size, for Xcode / fastlane if needed

Run from repo root:  python3 tools/gen_icons.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
FONTS = os.path.join(os.path.dirname(__file__), "..", "assets", "fonts")
SS = 4

NAVY = (20, 35, 61)
INK = (14, 22, 40)
RED = (230, 57, 70)
CREAM = (243, 235, 221)
GOLD = (255, 183, 3)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def vgrad(w, h, stops):
    """Vertical gradient; stops = [(t, (r,g,b))]."""
    img = Image.new("RGB", (1, h))
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                px[0, y] = lerp(c0, c1, (t - t0) / max(1e-6, t1 - t0))
                break
    return img.resize((w, h)).convert("RGBA")


def scenery(size, horizon=0.64, train=True):
    """Sunset sky, sun, skyline, water and (optionally) a train on a bridge."""
    S = size * SS
    hy = int(S * horizon)
    img = vgrad(S, S, [(0.0, (26, 36, 78)), (0.32, (64, 54, 110)), (0.52, (214, 98, 92)),
                       (horizon, (255, 176, 92)), (horizon + 0.001, (22, 70, 110)), (1.0, (9, 30, 56))])
    d = ImageDraw.Draw(img)
    # sun with glow
    sun_c = (int(S * 0.5), int(hy - S * 0.02))
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    r = S * 0.34
    gd.ellipse([sun_c[0] - r, sun_c[1] - r, sun_c[0] + r, sun_c[1] + r], fill=(255, 190, 110, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.08))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    r = S * 0.17
    d.ellipse([sun_c[0] - r, sun_c[1] - r, sun_c[0] + r, sun_c[1] + r], fill=(255, 214, 140, 255))
    # skyline silhouette
    sky = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sky)
    col = (36, 30, 66, 255)
    k = S / 1024.0

    def rect(x0, y0, x1, y1):
        sd.rectangle([x0 * k, y0 * k, x1 * k, y1 * k], fill=col)

    base = horizon * 1024
    # low city
    xs = 0
    heights = [22, 34, 18, 40, 26, 30, 16, 36, 24, 20, 38, 28, 18, 32, 22, 26]
    w = 1024 / len(heights)
    for i, hh in enumerate(heights):
        rect(i * w, base - hh, (i + 1) * w + 1, base + 2)
    # mosque (left): big dome, half domes, two minarets
    mx = 250
    sd.pieslice([(mx - 95) * k, (base - 150) * k, (mx + 95) * k, (base + 40) * k], 180, 360, fill=col)
    rect(mx - 110, base - 56, mx + 110, base + 2)
    for side in (-1, 1):
        cx = mx + side * 80
        sd.pieslice([(cx - 50) * k, (base - 100) * k, (cx + 50) * k, (base - 0) * k], 180, 360, fill=col)
    rect(mx - 4, base - 182, mx + 4, base - 140)
    for side in (-1, 1):
        x = mx + side * 150
        rect(x - 9, base - 230, x + 9, base)
        sd.polygon([((x - 11) * k, (base - 228) * k), ((x + 11) * k, (base - 228) * k), (x * k, (base - 292) * k)], fill=col)
        rect(x - 15, base - 170, x + 15, base - 162)
    # tower (right): cylinder with conical cap
    tx = 790
    rect(tx - 34, base - 190, tx + 34, base + 2)
    rect(tx - 42, base - 200, tx + 42, base - 186)
    sd.polygon([((tx - 40) * k, (base - 198) * k), ((tx + 40) * k, (base - 198) * k), (tx * k, (base - 286) * k)], fill=col)
    # small domes right
    for cx, rr in ((640, 46), (930, 40)):
        sd.pieslice([(cx - rr) * k, (base - rr * 1.6) * k, (cx + rr) * k, (base + rr * 0.4) * k], 180, 360, fill=col)
    img.alpha_composite(sky)
    d = ImageDraw.Draw(img)
    # water reflections
    for i in range(9):
        y = hy + S * (0.035 + i * 0.03)
        half = S * (0.2 - i * 0.017)
        if half <= 0:
            break
        a = int(170 - i * 16)
        d.rounded_rectangle([sun_c[0] - half, y, sun_c[0] + half, y + S * 0.008], radius=S * 0.004,
                            fill=(255, 200, 130, a))
    if train:
        _bridge_train(img, S, hy)
    return img.resize((size, size), Image.LANCZOS)


def _bridge_train(img, S, hy):
    d = ImageDraw.Draw(img)
    k = S / 1024.0
    deck = hy + 150 * k
    # bridge deck & piers
    d.rectangle([0, deck, S, deck + 20 * k], fill=INK + (255,))
    for x in (120, 420, 720, 980):
        d.rectangle([(x - 14) * k, deck, (x + 14) * k, S], fill=(12, 28, 50, 255))
    # train: three cars heading right
    top = deck - 74 * k
    for i, (x0, x1) in enumerate(((40, 330), (342, 632), (644, 960))):
        r = 22 * k
        d.rounded_rectangle([x0 * k, top, x1 * k, deck - 4 * k], radius=r, fill=CREAM + (255,))
        d.rectangle([x0 * k, deck - 30 * k, x1 * k, deck - 20 * k], fill=RED + (255,))
        # windows
        wx = x0 + 22
        while wx + 40 < x1 - 18:
            d.rounded_rectangle([wx * k, top + 14 * k, (wx + 40) * k, top + 38 * k], radius=6 * k, fill=(30, 64, 110, 255))
            wx += 54
    # nose highlight + headlight
    d.ellipse([940 * k, deck - 34 * k, 956 * k, deck - 18 * k], fill=(255, 236, 160, 255))


def metro_sign(size, cx, cy, half, mono=False):
    """Red rounded-square sign with a white M; returns an RGBA layer."""
    S = size * SS
    lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    k = SS
    cx, cy, h = cx * k, cy * k, half * k
    # drop shadow
    if not mono:
        sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle([cx - h, cy - h + h * 0.08, cx + h, cy + h + h * 0.1], radius=h * 0.36,
                                             fill=(0, 0, 0, 120))
        lay.alpha_composite(sh.filter(ImageFilter.GaussianBlur(h * 0.09)))
    d = ImageDraw.Draw(lay)
    if mono:
        d.rounded_rectangle([cx - h, cy - h, cx + h, cy + h], radius=h * 0.36, fill=(255, 255, 255, 255))
    else:
        d.rounded_rectangle([cx - h, cy - h, cx + h, cy + h], radius=h * 0.36, fill=(255, 255, 255, 255))
        d.rounded_rectangle([cx - h * 0.9, cy - h * 0.9, cx + h * 0.9, cy + h * 0.9], radius=h * 0.3, fill=RED + (255,))
    # M as a thick transit line with stations
    pts = [(-0.5, 0.5), (-0.5, -0.46), (0.0, 0.16), (0.5, -0.46), (0.5, 0.5)]
    pts = [(cx + x * h, cy + y * h) for x, y in pts]
    w = h * 0.28
    col = (0, 0, 0, 0) if mono else (255, 255, 255, 255)
    md = ImageDraw.Draw(lay)
    if mono:
        # punch the M out of the white plate
        mask = Image.new("L", (S, S), 0)
        mdd = ImageDraw.Draw(mask)
        mdd.line(pts, fill=255, width=int(w), joint="curve")
        for p in (pts[0], pts[-1]):
            mdd.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=255)
        a = lay.getchannel("A")
        a = Image.composite(Image.new("L", (S, S), 0), a, mask)
        lay.putalpha(a)
    else:
        md.line(pts, fill=col, width=int(w), joint="curve")
        for p in (pts[0], pts[-1]):
            md.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=col)
        # interchange dots on the M's joints
        for p in (pts[1], pts[2], pts[3]):
            r1, r2 = w * 0.62, w * 0.34
            md.ellipse([p[0] - r1, p[1] - r1, p[0] + r1, p[1] + r1], fill=NAVY + (255,))
            md.ellipse([p[0] - r2, p[1] - r2, p[0] + r2, p[1] + r2], fill=(255, 255, 255, 255))
    return lay.resize((size, size), Image.LANCZOS)


def icon(size=1024):
    img = scenery(size)
    img.alpha_composite(metro_sign(size, size * 0.5, size * 0.39, size * 0.235))
    return img


def splash():
    w, h = 1242, 2688
    sp = vgrad(w, h, [(0.0, (26, 36, 78)), (0.55, (16, 23, 36)), (1.0, (16, 23, 36))])
    sign = metro_sign(900, 450, 450, 200)
    sp.alpha_composite(sign, ((w - 900) // 2, int(h * 0.5) - 760))
    d = ImageDraw.Draw(sp)
    try:
        f1 = ImageFont.truetype(os.path.join(FONTS, "BricolageGrotesque.ttf"), 132)
        f1.set_variation_by_axes([96, 800, 100])
    except Exception:
        f1 = ImageFont.truetype(os.path.join(FONTS, "BricolageGrotesque.ttf"), 132)
    try:
        f2 = ImageFont.truetype(os.path.join(FONTS, "BricolageGrotesque.ttf"), 72)
        f2.set_variation_by_axes([96, 800, 100])
    except Exception:
        f2 = ImageFont.truetype(os.path.join(FONTS, "BricolageGrotesque.ttf"), 72)
    for txt, f, y, col in (("METRO TYCOON", f1, h * 0.5 + 110, CREAM), ("TÜRKİYE", f2, h * 0.5 + 270, GOLD)):
        tw = d.textlength(txt, font=f)
        d.text(((w - tw) / 2, y), txt, font=f, fill=col)
    return sp


def main():
    os.makedirs(ROOT, exist_ok=True)
    ico = icon(1024)
    ico.convert("RGB").save(os.path.join(ROOT, "icon.png"))
    ico.convert("RGB").resize((192, 192), Image.LANCZOS).save(os.path.join(ROOT, "icon_192.png"))
    ios = os.path.join(ROOT, "ios")
    os.makedirs(ios, exist_ok=True)
    for px in (40, 58, 60, 76, 80, 87, 114, 120, 152, 167, 180, 1024):
        ico.convert("RGB").resize((px, px), Image.LANCZOS).save(os.path.join(ios, "AppIcon-%d.png" % px))
    # Android adaptive: 432 canvas, visible circle ~ 66 % (sign inside the safe zone)
    fg = metro_sign(432, 216, 200, 92)
    fg.save(os.path.join(ROOT, "adaptive_foreground.png"))
    scenery(432, horizon=0.7).convert("RGB").save(os.path.join(ROOT, "adaptive_background.png"))
    metro_sign(432, 216, 216, 100, mono=True).save(os.path.join(ROOT, "adaptive_monochrome.png"))
    splash().convert("RGB").save(os.path.join(ROOT, "splash.png"))
    print("icons written to", ROOT)


if __name__ == "__main__":
    main()
