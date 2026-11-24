#!/usr/bin/env python3
"""Edits the social-media promo from the raw Movie Maker capture.

    python3 tools/make_promo.py <workdir> [--lang tr|en] [--no-vo]

<workdir> must contain raw.avi and capture.log (from tools/promo_capture.tscn).
Produces <workdir>/promo_<lang>[_novo].mp4  (1080x1920, 30 fps, H.264 + AAC).

Pipeline: cut scenes at the SCENE markers -> per-clip push-in, grade and vignette ->
xfade transitions -> animated caption cards (PIL) -> original music scored to the cut
points + whooshes + game SFX + optional Piper voice-over with sidechain ducking.
"""
import math
import os
import re
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FONT = os.path.join(ROOT, "assets/fonts/BricolageGrotesque.ttf")
BODY = os.path.join(ROOT, "assets/fonts/Nunito.ttf")
SFX = os.path.join(ROOT, "assets/audio")
W, H, FPS = 1080, 1920, 30
SR = 44100

INK = (20, 35, 61)
CREAM = (243, 235, 221)
YELLOW = (246, 180, 44)
STRIPES = [(226, 56, 79), (29, 114, 216), (31, 179, 158), (246, 180, 44)]

# scene: (marker, source offset s, duration s, transition into next, caption key)
SCENES = [
    ("hook", 0.0, 2.9, "smoothup", "hook"),
    ("build", 0.2, 4.3, "circleopen", "build"),
    ("tunnel", 0.25, 3.1, "slideleft", "tunnel"),
    ("night", 0.0, 3.2, "fadeblack", "night"),
    ("social", 0.6, 3.3, "hblur", "social"),
    ("crisis", 0.0, 3.2, "fadewhite", "crisis"),
    ("diagram", 0.15, 3.0, "zoomin", "diagram"),
    ("city_ankara", 0.15, 1.35, "slideleft", "ankara"),
    ("city_izmir", 0.15, 1.35, "slideleft", "izmir"),
    ("city_bursa", 0.15, 1.35, "slideleft", "bursa"),
    ("city_trabzon", 0.15, 1.45, "circleclose", "trabzon"),
    ("end", 0.6, 4.6, None, "end"),
]
XF = {"default": 0.32, "slideleft_city": 0.22}

TEXT = {
    "tr": {
        "hook": ("İSTANBUL'UN METROSUNU", "SEN KURSAYDIN?"),
        "build": ("Durakları çiz.", "Hattını aç."),
        "tunnel": ("BOĞAZ'IN ALTINDAN", "TÜNEL KAZ"),
        "night": ("ŞEHİR HİÇ UYUMAZ", "milyonlarca yolcu"),
        "social": ("HALK HER KARARINI", "KONUŞUYOR"),
        "crisis": ("GREV. DEPREM. ARIZA.", "kriz senin elinde"),
        "diagram": ("AĞINI BİR", "SANAT ESERİNE ÇEVİR"),
        "ankara": ("ANKARA", "kar fırtınası"),
        "izmir": ("İZMİR", "körfez vapurları"),
        "bursa": ("BURSA", "Uludağ teleferiği"),
        "trabzon": ("TRABZON", "dağ ile deniz arası"),
        "end": ("RAY AĞI", "YAKINDA · App Store & Google Play"),
        "badge": "7 ŞEHİR · 7 SİSTEM",
    },
    "en": {
        "hook": ("WHAT IF YOU BUILT", "ISTANBUL'S METRO?"),
        "build": ("Draw the stops.", "Open the line."),
        "tunnel": ("TUNNEL UNDER", "THE BOSPHORUS"),
        "night": ("THE CITY NEVER SLEEPS", "millions of riders"),
        "social": ("THE CITY TALKS ABOUT", "EVERY DECISION"),
        "crisis": ("STRIKES. QUAKES. FAILURES.", "the crisis is yours"),
        "diagram": ("TURN YOUR NETWORK", "INTO ART"),
        "ankara": ("ANKARA", "snow storm"),
        "izmir": ("IZMIR", "gulf ferries"),
        "bursa": ("BURSA", "Uludağ gondola"),
        "trabzon": ("TRABZON", "between mountain and sea"),
        "end": ("RAY AĞI", "COMING SOON · App Store & Google Play"),
        "badge": "7 CITIES · 7 SYSTEMS",
    },
}

VO = {
    "tr": {
        "hook": "İstanbul'un metrosunu, sen kursaydın?",
        "build": "Durakları çiz, hattını aç.",
        "tunnel": "Boğaz'ın altından tünel kaz.",
        "night": "Milyonlarca yolcuyu taşı.",
        "social": "Halk her kararını konuşuyor.",
        "crisis": "Grev, deprem, arıza. Kriz senin elinde.",
        "diagram": "Ağını bir sanat eserine çevir.",
        "ankara": "Yedi şehir. Yedi sistem.",
        "end": "Ray Ağı. Çok yakında.",
    },
}


def run(cmd):
    print(" ".join(cmd[:6]), "...")
    subprocess.run(cmd, check=True)


def font(size, weight=800):
    f = ImageFont.truetype(FONT, size)
    try:
        axes = f.get_variation_axes()
        vals = []
        for a in axes:
            n = a.get("name", b"")
            n = n.decode() if isinstance(n, bytes) else str(n)
            if "eight" in n:
                vals.append(weight)
            elif "idth" in n:
                vals.append(90)
            else:
                vals.append(48)
        f.set_variation_by_axes(vals)
    except Exception:
        pass
    return f


def stripe(draw, x, y, w, th=12):
    seg = w / 4
    for i, c in enumerate(STRIPES):
        draw.rounded_rectangle([x + i * seg, y, x + (i + 1) * seg, y + th], radius=th // 2, fill=c)
    for i in range(1, 4):
        cx = x + i * seg
        draw.ellipse([cx - th, y - th * 0.4, cx + th, y + th * 1.4], fill=INK)
        draw.ellipse([cx - th * 0.6, y, cx + th * 0.6, y + th], fill=(255, 255, 255))


def shadowed(img, box_img, pos):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    a = box_img.split()[3].point(lambda v: int(v * 0.45))
    blob = Image.new("RGBA", box_img.size, (0, 0, 0, 255))
    blob.putalpha(a)
    sh.paste(blob, (pos[0] + 10, pos[1] + 16), blob)
    sh = sh.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(sh)
    img.alpha_composite(box_img, pos)


def plate_card(line1, line2, y, accent, big=96, small=58, sub_style="yellow"):
    """Station-sign caption: ink plate with coloured bar, cream title, subtitle below."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    f1 = font(big, 800)
    f2 = font(small, 700)
    d0 = ImageDraw.Draw(img)
    tw = d0.textlength(line1, font=f1)
    sw = d0.textlength(line2, font=f2) if line2 else 0
    pw = int(max(tw, sw) + 120)
    ph = int(big * 1.25 + (small * 1.35 if line2 else 0) + 70)
    card = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle([0, 0, pw - 1, ph - 1], radius=28, fill=INK + (245,))
    d.rounded_rectangle([0, 0, 22, ph - 1], radius=11, fill=accent)
    d.text((70, 26), line1, font=f1, fill=CREAM)
    if line2:
        d.text((72, 26 + big * 1.2), line2, font=f2, fill=YELLOW if sub_style == "yellow" else CREAM)
    shadowed(img, card, ((W - pw) // 2, y))
    return img


def hook_card(line1, line2):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f1 = font(78, 800)
    f2 = font(128, 800)
    # top line on a plate
    tw = d.textlength(line1, font=f1)
    card = Image.new("RGBA", (int(tw + 90), 128), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0, 0, card.width - 1, 127], radius=24, fill=INK + (240,))
    cd.text((45, 18), line1, font=f1, fill=CREAM)
    shadowed(img, card, ((W - card.width) // 2, 560))
    # giant second line with heavy outline
    tw2 = d.textlength(line2, font=f2)
    if tw2 > W - 80:
        f2 = font(int(128 * (W - 80) / tw2), 800)
        tw2 = d.textlength(line2, font=f2)
    x = (W - tw2) / 2
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.text((x, 712), line2, font=f2, fill=YELLOW, stroke_width=14, stroke_fill=INK)
    shadowed(img, layer.crop((0, 0, W, H)), (0, 0))
    stripe(d, (W - 520) / 2, 905, 520, 16)
    return img


def badge_card(text):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    f = font(54, 800)
    d = ImageDraw.Draw(img)
    tw = d.textlength(text, font=f)
    card = Image.new("RGBA", (int(tw + 80), 96), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0, 0, card.width - 1, 95], radius=48, fill=YELLOW + (255,))
    cd.text((40, 14), text, font=f, fill=INK)
    shadowed(img, card, ((W - card.width) // 2, 1560))
    return img


def end_card(line1, line2):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    f2 = font(46, 700)
    d = ImageDraw.Draw(img)
    tw = d.textlength(line2, font=f2)
    card = Image.new("RGBA", (int(tw + 90), 110), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0, 0, card.width - 1, 109], radius=55, fill=YELLOW + (255,))
    cd.text((45, 24), line2, font=f2, fill=INK)
    shadowed(img, card, ((W - card.width) // 2, 1700))
    return img


# ----------------------------------------------------------------------------- audio

def read_wav(path, sr=SR):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(sr), "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def write_wav(path, sig, sr=SR):
    sig = np.clip(sig, -1, 1)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((sig * 32767).astype(np.int16).tobytes())


def add(buf, sig, t, gain=1.0):
    i = int(t * SR)
    if i >= len(buf):
        return
    e = min(len(buf), i + len(sig))
    buf[i:e] += sig[: e - i] * gain


def env(n, a, r):
    t = np.arange(n) / SR
    return np.minimum(1, t / max(a, 1e-4)) * np.exp(-t / max(r, 1e-4))


def kick():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    f = 48 + 110 * np.exp(-t * 28)
    return np.sin(2 * math.pi * np.cumsum(f) / SR) * np.exp(-t / 0.16) * 0.9


def snare():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    noise = np.random.default_rng(3).standard_normal(n)
    return (noise * 0.6 + np.sin(2 * math.pi * 190 * t) * 0.5) * np.exp(-t / 0.07) * 0.55


def hat():
    n = int(0.06 * SR)
    noise = np.random.default_rng(9).standard_normal(n)
    noise = np.diff(np.concatenate([[0], noise]))
    return noise * env(n, 0.001, 0.015) * 0.22


def impact():
    n = int(1.8 * SR)
    t = np.arange(n) / SR
    boom = np.sin(2 * math.pi * (40 + 60 * np.exp(-t * 6)) * t) * np.exp(-t / 0.5)
    noise = np.random.default_rng(1).standard_normal(n) * np.exp(-t / 0.12) * 0.4
    return (boom + noise) * 0.9


def riser(d):
    n = int(d * SR)
    t = np.arange(n) / SR
    noise = np.random.default_rng(4).standard_normal(n)
    k = np.linspace(0.02, 0.5, n)
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        acc += k[i] * (noise[i] - acc)
        y[i] = acc
    sweep = np.sin(2 * math.pi * np.cumsum(np.linspace(200, 1400, n)) / SR) * 0.15
    return (y * 0.8 + sweep) * (t / d) ** 2


def whoosh(d=0.45):
    n = int(d * SR)
    noise = np.random.default_rng(6).standard_normal(n)
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        k = 0.05 + 0.4 * math.sin(math.pi * i / n)
        acc += k * (noise[i] - acc)
        y[i] = acc
    return y * np.sin(np.linspace(0, math.pi, n)) ** 2 * 0.7


def music(total, cuts, quiet_ranges, drop_at, end_at):
    """Original 120 BPM track scored to the edit: riser into the hook hit, driving
    groove, filtered break during the diagram scene, snare roll into the cities,
    big impact + sustained chord on the end card."""
    bpm = 120.0
    beat = 60.0 / bpm
    buf = np.zeros(int((total + 2) * SR))
    prog = [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [261.63, 329.63, 392.0], [196.0, 246.94, 293.66]]
    t = 0.0
    nbeats = int(total / beat) + 1
    K, S, Hh = kick(), snare(), hat()
    for b in range(nbeats):
        tb = b * beat
        if tb >= end_at:
            break
        in_break = any(a <= tb < z for a, z in quiet_ranges)
        bar = b // 4
        ch = prog[bar % 4]
        if tb < drop_at:
            # intro: pulse only
            add(buf, K, tb, 0.35 if b % 2 == 0 else 0.0)
        else:
            if not in_break:
                add(buf, K, tb, 1.0)
                if b % 2 == 1:
                    add(buf, S, tb, 0.8)
                for h in range(2):
                    add(buf, Hh, tb + h * beat / 2, 1.0 if h else 0.6)
            # bass (sidechain-like gap after kick)
            n = int(beat * SR)
            tt = np.arange(n) / SR
            f = ch[0] / 2
            bass = (np.sin(2 * math.pi * f * tt) + 0.35 * np.sign(np.sin(2 * math.pi * f * tt))) * 0.16
            bass *= np.minimum(1, tt / 0.09)
            add(buf, bass * (0.4 if in_break else 1.0), tb)
            # arpeggio 16ths
            for k in range(4):
                fq = ch[(k + b) % 3] * (4 if k % 2 else 2)
                n2 = int(0.11 * SR)
                t2 = np.arange(n2) / SR
                saw = 2 * ((fq * t2) % 1) - 1
                add(buf, saw * np.exp(-t2 / 0.05) * (0.05 if in_break else 0.075), tb + k * beat / 4)
        # pad
        if b % 4 == 0:
            n = int(4 * beat * SR)
            tt = np.arange(n) / SR
            pad = sum(np.sin(2 * math.pi * f * tt) + 0.5 * np.sin(2 * math.pi * f * 1.005 * tt) for f in ch)
            pad *= np.minimum(1, tt / 0.4) * np.minimum(1, (tt[-1] - tt) / 0.3) * 0.03
            add(buf, pad, tb)
    # riser into the first drop, snare roll into the city montage
    r = riser(drop_at)
    add(buf, r, 0.0, 0.9)
    roll_start = quiet_ranges[0][1] - 1.0 if quiet_ranges else None
    if roll_start:
        for i in range(16):
            add(buf, S, roll_start + i * 1.0 / 16, 0.25 + i * 0.04)
    add(buf, impact(), drop_at, 0.9)
    add(buf, impact(), end_at, 1.0)
    # final chord
    n = int(4.5 * SR)
    tt = np.arange(n) / SR
    chord = sum(np.sin(2 * math.pi * f * tt) * (1 / (i + 1)) for i, f in enumerate([130.81, 196.0, 261.63, 329.63, 392.0]))
    add(buf, chord * np.minimum(1, tt / 0.02) * np.exp(-tt / 1.6) * 0.16, end_at)
    for c in cuts:
        add(buf, whoosh(), c - 0.25, 0.55)
    # simple stereo-less glue: soft clip
    buf = np.tanh(buf * 1.3) * 0.8
    return buf[: int(total * SR)]


def piper_vo(text, out, workdir):
    model = os.path.join(workdir, "..", "piper", "tr_TR-dfki-medium.onnx")
    if not os.path.exists(model):
        return False
    p = subprocess.run([sys.executable, "-m", "piper", "-m", model, "-f", out, "--length-scale", "0.88",
                        "--sentence-silence", "0.05"], input=text.encode(), capture_output=True)
    return p.returncode == 0 and os.path.exists(out)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    wd = os.path.abspath(sys.argv[1])
    lang = "tr"
    if "--lang" in sys.argv:
        lang = sys.argv[sys.argv.index("--lang") + 1]
    use_vo = "--no-vo" not in sys.argv and lang in VO
    log = open(os.path.join(wd, "capture.log"), encoding="utf-8").read()
    markers = {m.group(1): int(m.group(2)) for m in re.finditer(r"SCENE (\S+) (\d+)", log)}
    raw = os.path.join(wd, "raw.avi")
    T = TEXT[lang]

    # ---------- timeline
    starts = []
    t = 0.0
    xfs = []
    for i, (mk, off, dur, tr, cap) in enumerate(SCENES):
        starts.append(t)
        if tr:
            x = XF["slideleft_city"] if mk.startswith("city_") else XF["default"]
            xfs.append((tr, x))
            t += dur - x
        else:
            t += dur
    total = t
    print("total duration %.2f s" % total)

    # ---------- captions
    cards = []  # (png, t0, t1, y_anim)
    cdir = os.path.join(wd, "cards_" + lang)
    os.makedirs(cdir, exist_ok=True)
    def card(name, img, t0, t1):
        p = os.path.join(cdir, name + ".png")
        img.save(p)
        cards.append((p, t0, t1))
    for i, (mk, off, dur, tr, cap) in enumerate(SCENES):
        s0 = starts[i]
        s1 = s0 + dur - (xfs[i][1] if i < len(xfs) else 0)
        l1, l2 = T[cap]
        if cap == "hook":
            card(cap, hook_card(l1, l2), s0 + 0.15, s1 + 0.1)
        elif cap == "end":
            card(cap, end_card(l1, l2), s0 + 0.5, total)
        elif mk.startswith("city_"):
            card(cap, plate_card(l1, l2, 1180, STRIPES[i % 4], big=120, small=50), s0 + 0.05, s1)
        elif cap in ("build", "social", "tunnel", "crisis"):
            y = {"build": 1080, "social": 1430, "tunnel": 1380, "crisis": 300}[cap]
            card(cap, plate_card(l1, l2, y, STRIPES[(i + 1) % 4], big=78, small=62, sub_style="cream" if cap == "build" else "yellow"), s0 + 0.2, s1)
        else:
            card(cap, plate_card(l1, l2, 1250, STRIPES[i % 4], big=82, small=56), s0 + 0.2, s1)
    city_i = [i for i, s in enumerate(SCENES) if s[0].startswith("city_")]
    card("badge", badge_card(T["badge"]), starts[city_i[0]] + 0.1, starts[city_i[-1]] + SCENES[city_i[-1]][2] - 0.2)

    # ---------- audio
    cut_times = [starts[i + 1] for i in range(len(SCENES) - 1)]
    di = [s[0] for s in SCENES].index("diagram")
    quiet = [(starts[di], starts[di + 1])]
    end_at = starts[-1]
    mus = music(total, cut_times, quiet, starts[1], end_at)
    sfx = np.zeros_like(mus)
    def sfx_at(name, tt, g=1.0):
        p = os.path.join(SFX, name)
        if os.path.exists(p):
            add(sfx, read_wav(p), tt, g)
    bi = 1
    for k in range(6):
        sfx_at("place.wav", starts[bi] + (0.38 * (k + 1)) - SCENES[bi][1], 0.6)
    sfx_at("build.wav", starts[bi] + 2.7 - SCENES[bi][1], 0.8)
    sfx_at("chime.wav", starts[bi] + 2.75 - SCENES[bi][1], 0.5)
    si = [s[0] for s in SCENES].index("social")
    sfx_at("goal.wav", starts[si] + 0.65, 0.5)
    ci = [s[0] for s in SCENES].index("crisis")
    add(sfx, impact() * 0.8, starts[ci] + 0.05, 0.7)
    sfx_at("chime.wav", starts[ci] + 1.35, 0.5)
    ii = [s[0] for s in SCENES].index("city_izmir")
    sfx_at("amb/gull_2.ogg", starts[ii] + 0.1, 0.5)
    sfx_at("amb/ferry_horn.ogg", starts[ii] + 0.2, 0.35)
    sfx_at("year.wav", end_at + 0.2, 0.45)

    vo = np.zeros_like(mus)
    has_vo = False
    if use_vo:
        vdir = os.path.join(wd, "vo_" + lang)
        os.makedirs(vdir, exist_ok=True)
        for key, text in VO[lang].items():
            idx = [s[4] for s in SCENES].index(key)
            out = os.path.join(vdir, key + ".wav")
            if not os.path.exists(out) and not piper_vo(text, out, wd):
                continue
            v = read_wav(out)
            # voice polish: high-pass + gentle compression + short room
            v = v - np.convolve(v, np.ones(64) / 64, mode="same")
            v = np.tanh(v * 2.2) * 0.55
            d = int(0.045 * SR)
            v2 = v.copy()
            v2[d:] += v[:-d] * 0.12
            lead = 0.05 if key == "hook" else 0.12
            add(vo, v2, starts[idx] + lead, 1.0)
            has_vo = True
    # duck music under the voice
    if has_vo:
        envv = np.abs(vo)
        win = int(0.12 * SR)
        envv = np.convolve(envv, np.ones(win) / win, mode="same")
        duck = 1.0 - np.clip(envv * 9.0, 0, 0.55)
        mus = mus * duck
    mix = mus * 0.85 + sfx * 0.7 + vo * 1.15
    mix = mix / max(1e-6, np.max(np.abs(mix))) * 0.93
    apath = os.path.join(wd, "mix_%s%s.wav" % (lang, "" if has_vo else "_novo"))
    write_wav(apath, mix)

    # ---------- video graph
    inputs = []
    fc = []
    for i, (mk, off, dur, tr, cap) in enumerate(SCENES):
        ss = markers[mk] / FPS + off
        inputs += ["-ss", "%.3f" % ss, "-t", "%.3f" % dur, "-i", raw]
        z = 0.07 if mk != "hook" else 0.04
        fc.append(
            "[%d:v]fps=%d,setpts=PTS-STARTPTS,scale=w='trunc(%d*(1+%.3f*t/%.3f)/2)*2':h=-2:eval=frame,"
            "crop=%d:%d,eq=contrast=1.06:saturation=1.14:gamma=0.98,vignette=PI/6,format=yuv420p,setsar=1[v%d]"
            % (i, FPS, W, z, dur, W, H, i))
    last = "v0"
    acc = SCENES[0][2]
    for i in range(1, len(SCENES)):
        tr, x = xfs[i - 1]
        off = acc - x
        out = "x%d" % i
        fc.append("[%s][v%d]xfade=transition=%s:duration=%.3f:offset=%.3f[%s]" % (last, i, tr, x, off, out))
        last = out
        acc = off + SCENES[i][2]
    # caption overlays with slide/fade
    base_idx = len(SCENES)
    for k, (png, t0, t1) in enumerate(cards):
        inputs += ["-loop", "1", "-t", "%.3f" % (total + 1), "-i", png]
        ii = base_idx + k
        fc.append("[%d:v]format=rgba,fade=in:st=%.3f:d=0.22:alpha=1,fade=out:st=%.3f:d=0.18:alpha=1[c%d]"
                  % (ii, t0, max(t0 + 0.3, t1 - 0.18), k))
        out = "o%d" % k
        fc.append("[%s][c%d]overlay=x=0:y='if(lt(t,%.3f),0,60*max(0,1-(t-%.3f)/0.25)*(1-(t-%.3f)/0.25))':enable='between(t,%.3f,%.3f)'[%s]"
                  % (last, k, t0, t0, t0, t0, t1, out))
        last = out
    inputs += ["-i", apath]
    aidx = base_idx + len(cards)
    out_path = os.path.join(wd, "promo_%s%s.mp4" % (lang, "" if has_vo else "_novo"))
    cmd = ["ffmpeg", "-v", "error", "-y"] + inputs + [
        "-filter_complex", ";".join(fc), "-map", "[%s]" % last, "-map", "%d:a" % aidx,
        "-t", "%.3f" % total, "-r", str(FPS), "-c:v", "libx264", "-preset", "slow", "-crf", "19",
        "-pix_fmt", "yuv420p", "-profile:v", "high", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", out_path]
    run(cmd)
    print("wrote", out_path)


if __name__ == "__main__":
    main()
