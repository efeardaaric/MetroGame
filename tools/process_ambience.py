#!/usr/bin/env python3
"""Builds city ambience assets.

Inputs: a directory with the CC0 source files downloaded from OpenGameArt
(see assets/audio/amb/CREDITS.md for exact sources). Outputs mono OGG files into
assets/audio/amb/. Also synthesises the ferry horn, tram bell and steppe wind.

Usage:  python3 tools/process_ambience.py <download_dir>
Needs ffmpeg (with libvorbis) and numpy.
"""
import math
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "amb")


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def encode(name, sig, q=4):
    sig = np.asarray(sig, dtype=np.float64)
    peak = np.max(np.abs(sig)) or 1.0
    sig = sig / peak * 0.9
    os.makedirs(OUT, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((sig * 32767).astype(np.int16).tobytes())
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(q), dst], check=True)
    os.remove(tmp)
    print("wrote", dst, f"{len(sig) / SR:.1f}s")


def trim_silence(x, thr=0.02):
    a = np.abs(x)
    idx = np.where(a > thr * a.max())[0]
    if len(idx) == 0:
        return x
    s, e = max(0, idx[0] - int(0.01 * SR)), min(len(x), idx[-1] + int(0.05 * SR))
    y = x[s:e].copy()
    fade = min(len(y) // 4, int(0.04 * SR))
    y[-fade:] *= np.linspace(1, 0, fade)
    return y


def seamless(x, xfade_s=1.5):
    """Make a loop by cross-fading the tail into the head."""
    n = int(xfade_s * SR)
    if len(x) < 3 * n:
        return x
    head = x[:n]
    tail = x[-n:]
    t = np.linspace(0, 1, n)
    mixed = tail * np.cos(t * math.pi / 2) + head * np.sin(t * math.pi / 2)
    return np.concatenate([mixed, x[n:-n]])


def concat_xfade(parts, xf=0.6):
    n = int(xf * SR)
    out = parts[0]
    for p in parts[1:]:
        t = np.linspace(0, 1, n)
        out = np.concatenate([out[:-n], out[-n:] * (1 - t) + p[:n] * t, p[n:]])
    return out


def lowpass(x, alpha):
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def ferry_horn():
    # Deep two-blast ship horn (original synthesis)
    def blast(dur):
        n = int(dur * SR)
        t = np.arange(n) / SR
        f = 98.0
        sig = sum((1.0 / k) * np.sin(2 * math.pi * f * k * t + 0.2 * k) for k in range(1, 9))
        sig += 0.6 * sum((1.0 / k) * np.sin(2 * math.pi * f * 1.26 * k * t) for k in range(1, 6))
        env = np.minimum(1, t / 0.15) * np.minimum(1, (dur - t) / 0.35)
        vib = 1 + 0.01 * np.sin(2 * math.pi * 5 * t)
        return sig * env * vib
    gap = np.zeros(int(0.35 * SR))
    s = np.concatenate([blast(1.1), gap, blast(1.8)])
    # distance: simple echo + lowpass
    d = int(0.28 * SR)
    s = np.concatenate([s, np.zeros(d * 3)])
    for k in range(1, 4):
        s[d * k:] += s[:-d * k] * (0.35 ** k)
    return lowpass(s, 0.25)


def tram_bell():
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for off in (0.0, 0.22):
        o = int(off * SR)
        tt = t[: n - o]
        b = (np.sin(2 * math.pi * 1320 * tt) + 0.6 * np.sin(2 * math.pi * 1320 * 2.42 * tt) * np.exp(-tt * 9)
             + 0.3 * np.sin(2 * math.pi * 1320 * 3.9 * tt) * np.exp(-tt * 14))
        out[o:] += b * np.exp(-tt * 4.5)
    return out


def steppe_wind(dur=14.0):
    n = int(dur * SR)
    rng = np.random.default_rng(3)
    x = rng.standard_normal(n)
    y = lowpass(x, 0.03)
    y2 = lowpass(x, 0.12) - lowpass(x, 0.03)
    t = np.arange(n) / SR
    gust = 0.55 + 0.45 * np.sin(2 * math.pi * t / dur * 2) * np.sin(2 * math.pi * t / dur * 3 + 1)
    return seamless((y * 3 + y2 * 0.8) * gust, 2.0)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    f = lambda n: os.path.join(src, n)
    # gulls
    gulls = ["Seagull_Ambient_1.wav", "Seagull_Ambient_2.wav", "Seagull_Ambient_3.wav",
             "Seagull_Ambient_4.wav", "Seagull_Ambient_5.wav", "Seagull_Big_Ambient_2.wav"]
    for i, g in enumerate(gulls):
        if os.path.exists(f(g)):
            encode("gull_%d" % (i + 1), trim_silence(decode(f(g))), 4)
    # sea loop
    waves = ["wave_01_cc0-18363__jasinski__alkaibeach.flac", "wave_01_cc0-11505__transitking__wavesound.flac",
             "wave_02_cc0-18363__jasinski__alkaibeach.flac", "wave_03_cc0-11505__transitking__wavesound.flac"]
    parts = [decode(f(w)) for w in waves if os.path.exists(f(w))]
    if parts:
        sea = concat_xfade(parts * 2, 0.8)
        encode("sea_loop", seamless(lowpass(sea, 0.35), 1.2), 3)
    # city traffic loop
    if os.path.exists(f("gatve_Varniu_2.ogg")):
        city = decode(f("gatve_Varniu_2.ogg"))[: SR * 40]
        encode("city_loop", seamless(lowpass(city, 0.2), 2.5), 3)
    encode("ferry_horn", ferry_horn(), 4)
    encode("tram_bell", tram_bell(), 4)
    encode("wind_loop", steppe_wind(), 3)


if __name__ == "__main__":
    main()
