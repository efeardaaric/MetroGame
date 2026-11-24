#!/usr/bin/env python3
"""Frames raw store screenshots with a marketing caption (same output size).

  python3 tools/frame_store_shots.py RAW_DIR OUT_DIR tr|en
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = os.path.join(os.path.dirname(__file__), "..", "assets", "fonts", "BricolageGrotesque.ttf")
CAPTIONS = {
    "01_menu": ("İstanbul'dan Trabzon'a", "7 gerçek şehir", "From Istanbul to Trabzon", "7 real Turkish cities"),
    "02_network": ("Kendi metro ağını", "sıfırdan kur", "Build your metro", "network from scratch"),
    "03_derby": ("Derbi günü trafiği", "haritada canlı", "Watch derby-day", "traffic jam the roads"),
    "04_night": ("Gece gündüz", "yaşayan şehirler", "Cities alive", "day and night"),
    "05_event": ("Gerçek etkinliklere", "şehri hazırla", "Get the city ready", "for real-world events"),
    "06_election": ("Seçimleri kazan,", "görevde kal", "Win elections", "to stay in office"),
    "07_social": ("Şehir sosyal medyada", "seni konuşuyor", "The city reacts", "on social media"),
    "08_profile": ("Boğaz'ın altından", "derin tüneller kaz", "Dig deep tunnels", "under the Bosphorus"),
}


def font(size):
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_axes([96, 800, 100])
    except Exception:
        pass
    return f


def frame(src, dst, lang):
    shot = Image.open(src).convert("RGB")
    W, H = shot.size
    name = os.path.splitext(os.path.basename(src))[0]
    cap = CAPTIONS.get(name)
    out = Image.new("RGB", (W, H))
    # navy → indigo gradient
    top, bot = (26, 36, 78), (12, 18, 32)
    g = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / (H - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    out.paste(g.resize((W, H)))
    d = ImageDraw.Draw(out)
    head = int(H * 0.2)
    if cap:
        l1, l2 = (cap[0], cap[1]) if lang == "tr" else (cap[2], cap[3])
        fs = int(min(W, H * 0.46) * 0.082)
        f1 = font(fs)
        f2 = font(fs)
        for txt, f, y, col in ((l1, f1, head * 0.28, (243, 235, 221)), (l2, f2, head * 0.28 + fs * 1.22, (255, 183, 3))):
            tw = d.textlength(txt, font=f)
            d.text(((W - tw) / 2, y), txt, font=f, fill=col)
    # screenshot as a rounded "phone screen"
    scale = (H - head - H * 0.03) / H
    sw, sh = int(W * scale), int(H * scale)
    small = shot.resize((sw, sh), Image.LANCZOS)
    x, y = (W - sw) // 2, head
    r = int(W * 0.05)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=r, fill=255)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x - 6, y + 10, x + sw + 6, y + sh + 22], radius=r, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(W * 0.015))
    out = out.convert("RGBA")
    out.alpha_composite(shadow)
    d = ImageDraw.Draw(out)
    d.rounded_rectangle([x - 8, y - 8, x + sw + 8, y + sh + 8], radius=r + 8, fill=(243, 235, 221, 255))
    out.paste(small, (x, y), mask)
    out.convert("RGB").save(dst, quality=92)


def main():
    raw, dst, lang = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(dst, exist_ok=True)
    for fn in sorted(os.listdir(raw)):
        if fn.endswith(".png"):
            frame(os.path.join(raw, fn), os.path.join(dst, fn.replace(".png", ".jpg")), lang)
    print("framed", dst)


if __name__ == "__main__":
    main()
