#!/usr/bin/env python3
"""Generates the app icon (1024 master + Android adaptive layers) and splash art.

Run from repo root:  python3 tools/gen_icons.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
S = 1024


def rounded_path(pts, r, steps=10):
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = pts[i - 1], pts[i], pts[i + 1]
        def norm(v):
            l = math.hypot(*v) or 1
            return (v[0] / l, v[1] / l)
        la = math.hypot(a[0] - b[0], a[1] - b[1])
        lc = math.hypot(c[0] - b[0], c[1] - b[1])
        rr = min(r, la * 0.45, lc * 0.45)
        na, nc = norm((a[0] - b[0], a[1] - b[1])), norm((c[0] - b[0], c[1] - b[1]))
        p0 = (b[0] + na[0] * rr, b[1] + na[1] * rr)
        p2 = (b[0] + nc[0] * rr, b[1] + nc[1] * rr)
        for s in range(steps + 1):
            t = s / steps
            q0 = (p0[0] + (b[0] - p0[0]) * t, p0[1] + (b[1] - p0[1]) * t)
            q1 = (b[0] + (p2[0] - b[0]) * t, b[1] + (p2[1] - b[1]) * t)
            out.append((q0[0] + (q1[0] - q0[0]) * t, q0[1] + (q1[1] - q0[1]) * t))
    out.append(pts[-1])
    return out


def thick_line(d, pts, w, col):
    d.line(pts, fill=col, width=int(w), joint="curve")
    r = w / 2
    for p in (pts[0], pts[-1]):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)


def draw_motif(img, scale=1.0, offset=(0, 0)):
    ss = 4
    big = Image.new("RGBA", (img.width * ss, img.height * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    cx, cy = img.width * ss / 2 + offset[0] * ss, img.height * ss / 2 + offset[1] * ss
    k = scale * ss
    lines = [
        ((230, 57, 70), [(-330, 230), (-150, 230), (-20, 100), (0, 0)]),
        ((29, 114, 216), [(330, -230), (150, -230), (20, -100), (0, 0)]),
        ((255, 183, 3), [(-330, -150), (-130, -150), (0, 0), (130, 150), (330, 150)]),
    ]
    for col, raw in lines:
        pts = [(cx + x * k, cy + y * k) for x, y in raw]
        rp = rounded_path(pts, 70 * k)
        thick_line(d, rp, 96 * k, (255, 255, 255, 255))
        thick_line(d, rp, 68 * k, col + (255,))
    r1, r2, r3 = 112 * k, 84 * k, 36 * k
    d.ellipse([cx - r1, cy - r1, cx + r1, cy + r1], fill=(31, 37, 51, 255))
    d.ellipse([cx - r2, cy - r2, cx + r2, cy + r2], fill=(255, 255, 255, 255))
    d.ellipse([cx - r3, cy - r3, cx + r3, cy + r3], fill=(31, 37, 51, 255))
    big = big.resize(img.size, Image.LANCZOS)
    img.alpha_composite(big)


def background(size):
    img = Image.new("RGBA", (size, size), (16, 23, 36, 255))
    # soft radial glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    r = size * 0.42
    gd.ellipse([size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r], fill=(46, 70, 110, 255))
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.12))
    img.alpha_composite(glow)
    return img


def main():
    os.makedirs(ROOT, exist_ok=True)
    icon = background(S)
    draw_motif(icon, 1.0)
    icon.convert("RGB").save(os.path.join(ROOT, "icon.png"))
    icon.convert("RGB").resize((192, 192), Image.LANCZOS).save(os.path.join(ROOT, "icon_192.png"))
    # Android adaptive: foreground (motif inside 66% safe zone) + background
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    draw_motif(fg, 432 / S * 0.62)
    fg.save(os.path.join(ROOT, "adaptive_foreground.png"))
    bg = background(432)
    bg.convert("RGB").save(os.path.join(ROOT, "adaptive_background.png"))
    mono = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    draw_motif(mono, 432 / S * 0.62)
    px = mono.load()
    for y in range(432):
        for x in range(432):
            a = px[x, y][3]
            px[x, y] = (255, 255, 255, a)
    mono.save(os.path.join(ROOT, "adaptive_monochrome.png"))
    # splash (portrait 1242x2688 safe; centred motif)
    sp = Image.new("RGBA", (1242, 2688), (16, 23, 36, 255))
    motif = Image.new("RGBA", (1242, 1242), (0, 0, 0, 0))
    draw_motif(motif, 0.9)
    sp.alpha_composite(motif, (0, (2688 - 1242) // 2 - 120))
    sp.convert("RGB").save(os.path.join(ROOT, "splash.png"))
    print("icons written to", ROOT)


if __name__ == "__main__":
    main()
