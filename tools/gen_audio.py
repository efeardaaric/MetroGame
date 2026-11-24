#!/usr/bin/env python3
"""Generates all original sound effects and the ambient music loop as WAV files.

Run from the repository root:  python3 tools/gen_audio.py
Output: assets/audio/*.wav  (16-bit mono)
"""
import math
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def env(n, a=0.005, r=0.2, sr=SR):
    t = np.arange(n) / sr
    e = np.minimum(1.0, t / max(a, 1e-4))
    e *= np.exp(-t / max(r, 1e-4))
    return e


def tone(freq, dur, kind="sine", a=0.005, r=0.2, vol=0.5, sr=SR):
    n = int(dur * sr)
    t = np.arange(n) / sr
    if kind == "sine":
        w = np.sin(2 * math.pi * freq * t)
    elif kind == "bell":
        w = (np.sin(2 * math.pi * freq * t) + 0.45 * np.sin(2 * math.pi * freq * 2.76 * t) * np.exp(-t * 6)
             + 0.25 * np.sin(2 * math.pi * freq * 5.4 * t) * np.exp(-t * 10))
    elif kind == "tri":
        w = 2 * np.abs(2 * ((freq * t) % 1) - 1) - 1
    elif kind == "soft":
        w = np.sin(2 * math.pi * freq * t) + 0.3 * np.sin(4 * math.pi * freq * t)
    else:
        w = np.sin(2 * math.pi * freq * t)
    return w * env(n, a, r, sr) * vol


def mix(*parts):
    n = max(len(p[1]) + int(p[0] * SR) for p in parts)
    out = np.zeros(n)
    for off, sig in parts:
        o = int(off * SR)
        out[o:o + len(sig)] += sig
    return out


def save(name, sig, sr=SR):
    sig = np.asarray(sig, dtype=np.float64)
    peak = np.max(np.abs(sig)) or 1.0
    if peak > 0.95:
        sig = sig / peak * 0.95
    data = (sig * 32767).astype(np.int16)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    print("wrote", path, f"{len(data) / sr:.2f}s")


def noise(dur, vol=0.3, lp=0.2):
    n = int(dur * SR)
    x = np.random.default_rng(7).standard_normal(n)
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        acc += lp * (x[i] - acc)
        y[i] = acc
    return y * vol


def main():
    os.makedirs(OUT, exist_ok=True)
    save("tap", tone(1250, 0.06, "sine", 0.001, 0.018, 0.5))
    save("place", mix((0, tone(660, 0.18, "bell", 0.002, 0.08, 0.45)), (0.03, tone(990, 0.15, "sine", 0.002, 0.05, 0.2))))
    save("undo", mix((0, tone(740, 0.12, "soft", 0.002, 0.05, 0.4)), (0.05, tone(520, 0.14, "soft", 0.002, 0.06, 0.35))))
    # build: low thump + rising bell
    thump = tone(110, 0.3, "sine", 0.002, 0.09, 0.8)
    save("build", mix((0, thump), (0.0, noise(0.15, 0.25, 0.05) * env(int(0.15 * SR), 0.001, 0.04)),
                      (0.05, tone(523.25, 0.4, "bell", 0.003, 0.18, 0.35)),
                      (0.13, tone(783.99, 0.5, "bell", 0.003, 0.22, 0.3))))
    save("cash", mix((0, tone(1318.5, 0.25, "bell", 0.001, 0.08, 0.35)), (0.07, tone(1975.5, 0.35, "bell", 0.001, 0.12, 0.3))))
    save("error", mix((0, tone(220, 0.16, "tri", 0.004, 0.08, 0.35)), (0.11, tone(185, 0.2, "tri", 0.004, 0.09, 0.35))))
    # station chime (original two-note "ding-dong")
    save("chime", mix((0, tone(830.6, 0.9, "bell", 0.002, 0.35, 0.5)), (0.32, tone(659.3, 1.1, "bell", 0.002, 0.45, 0.5))))
    # goal: major arpeggio
    notes = [523.25, 659.25, 783.99, 1046.5]
    save("goal", mix(*[(i * 0.09, tone(f, 0.7, "bell", 0.002, 0.3, 0.35)) for i, f in enumerate(notes)]))
    notes = [392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5]
    save("year", mix(*[(i * 0.1, tone(f, 1.0, "bell", 0.002, 0.4, 0.3)) for i, f in enumerate(notes)],
                     (0.6, tone(261.6, 1.5, "soft", 0.05, 0.6, 0.3))))
    sw = noise(0.28, 0.6, 0.12)
    n = len(sw)
    shape = np.sin(np.linspace(0, math.pi, n)) ** 2
    save("swoosh", sw * shape * 0.6)
    music()
    music_variant("music_night", 68, [[146.83, 185.0, 220.0, 277.18], [123.47, 146.83, 185.0, 220.0],
                                      [98.0, 123.47, 146.83, 185.0], [110.0, 138.59, 164.81, 220.0]], soft=True)
    music_variant("music_tense", 104, [[110.0, 130.81, 164.81, 220.0], [87.31, 110.0, 130.81, 174.61],
                                       [73.42, 87.31, 110.0, 146.83], [82.41, 103.83, 123.47, 164.81]], soft=False)


def music_variant(name, bpm, chords, soft):
    """Mood loops for the dynamic soundtrack (same structure as the main loop)."""
    sr = 22050
    beat = 60.0 / bpm
    bars = 16
    n = int(bars * 4 * beat * sr)
    out = np.zeros(n)
    bar_len = 4 * beat
    rng = np.random.default_rng(11 if soft else 5)
    for b in range(bars):
        ch = chords[(b // 2) % 4]
        start = b * bar_len
        s0 = int(start * sr)
        seg_n = int(bar_len * sr)
        tt = np.arange(seg_n) / sr
        pad = sum(np.sin(2 * math.pi * f * tt) + 0.4 * np.sin(2 * math.pi * f * 1.004 * tt) for f in ch)
        env_p = np.minimum(1, tt / (0.9 if soft else 0.2)) * np.minimum(1, (tt[-1] - tt) / 0.3 + 0.02)
        e = min(n, s0 + seg_n)
        out[s0:e] += (pad * env_p * (0.045 if soft else 0.03))[: e - s0]
        steps = 4 if soft else 8
        for k in range(steps):
            st = start + k * bar_len / steps
            if soft and rng.random() < 0.35:
                continue
            f = ch[(k * 3 + b) % 4] * (2 if soft else 1)
            ln = int((1.2 if soft else 0.18) * sr)
            t2 = np.arange(ln) / sr
            if soft:
                note = (np.sin(2 * math.pi * f * t2) + 0.25 * np.sin(4 * math.pi * f * t2)) * np.exp(-t2 / 0.5) * 0.06
            else:
                saw = 2 * ((f * t2) % 1) - 1
                note = saw * np.exp(-t2 / 0.06) * 0.09
            note *= np.minimum(1, t2 / 0.005)
            a0 = int(st * sr)
            e2 = min(n, a0 + ln)
            out[a0:e2] += note[: e2 - a0]
            if e2 - a0 < ln:
                out[: ln - (e2 - a0)] += note[e2 - a0:]
        if not soft:
            # pulsing low drum on every beat
            for k in range(4):
                a0 = int((start + k * beat) * sr)
                ln = int(0.25 * sr)
                t2 = np.arange(ln) / sr
                kick = np.sin(2 * math.pi * (55 + 60 * np.exp(-t2 * 30)) * t2) * np.exp(-t2 / 0.09) * 0.25
                e2 = min(n, a0 + ln)
                out[a0:e2] += kick[: e2 - a0]
    d = int(0.29 * sr)
    for _ in range(3):
        out[d:] += out[:-d] * (0.3 if soft else 0.18)
    save(name, out, sr)


def music():
    """~64 s ambient loop: soft pads + gentle arpeggio, perfectly loopable."""
    sr = 32000
    bpm = 90
    beat = 60.0 / bpm
    bars = 24
    dur = bars * 4 * beat
    n = int(dur * sr)
    t = np.arange(n) / sr
    out = np.zeros(n)
    # chord progression (Am7 - Fmaj7 - Cmaj7 - G6), each 2 bars, repeated
    chords = [
        [220.0, 261.63, 329.63, 392.0],
        [174.61, 220.0, 261.63, 329.63],
        [261.63, 329.63, 392.0, 493.88],
        [196.0, 246.94, 293.66, 329.63],
    ]
    bar_len = 4 * beat
    for b in range(bars):
        ch = chords[(b // 2) % 4]
        start = b * bar_len
        if b % 2 == 0:
            seg_n = int(2 * bar_len * sr)
            s0 = int(start * sr)
            tt = np.arange(seg_n) / sr
            pad = np.zeros(seg_n)
            for f in ch:
                pad += np.sin(2 * math.pi * f * tt + 0.3 * np.sin(2 * math.pi * 0.25 * tt))
                pad += 0.5 * np.sin(2 * math.pi * f * 1.003 * tt)
            a = np.minimum(1, tt / 0.8) * np.minimum(1, (tt[-1] - tt) / 0.8 + 0.05)
            seg = pad * a * 0.05
            e = min(n, s0 + seg_n)
            out[s0:e] += seg[: e - s0]
        # arpeggio eighths
        pattern = [0, 2, 1, 3, 2, 1, 3, 2]
        for k in range(8):
            if (b * 8 + k) % 16 == 15:
                continue
            f = ch[pattern[k]] * 2
            st = start + k * beat / 2
            ln = int(0.9 * sr)
            tt = np.arange(ln) / sr
            note = (np.sin(2 * math.pi * f * tt) + 0.3 * np.sin(2 * math.pi * f * 2 * tt) * np.exp(-tt * 8))
            note *= np.minimum(1, tt / 0.004) * np.exp(-tt / 0.28) * 0.07
            s0 = int(st * sr)
            e = min(n, s0 + ln)
            out[s0:e] += note[: e - s0]
            if e - s0 < ln:  # wrap tail for seamless loop
                rest = ln - (e - s0)
                out[:rest] += note[e - s0:]
        # soft bass on beats 1 and 3
        for k in (0, 2):
            f = ch[0] / 2
            st = start + k * beat
            ln = int(1.4 * sr)
            tt = np.arange(ln) / sr
            note = np.sin(2 * math.pi * f * tt) * np.minimum(1, tt / 0.02) * np.exp(-tt / 0.6) * 0.12
            s0 = int(st * sr)
            e = min(n, s0 + ln)
            out[s0:e] += note[: e - s0]
            if e - s0 < ln:
                out[: ln - (e - s0)] += note[e - s0:]
    # simple stereo-less reverb (feedback delay)
    d = int(0.23 * sr)
    for _ in range(3):
        out[d:] += out[:-d] * 0.25
    save("music", out, sr)


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--music-only":
        os.makedirs(OUT, exist_ok=True)
        music_variant("music_night", 68, [[146.83, 185.0, 220.0, 277.18], [123.47, 146.83, 185.0, 220.0],
                                          [98.0, 123.47, 146.83, 185.0], [110.0, 138.59, 164.81, 220.0]], soft=True)
        music_variant("music_tense", 104, [[110.0, 130.81, 164.81, 220.0], [87.31, 110.0, 130.81, 174.61],
                                           [73.42, 87.31, 110.0, 146.83], [82.41, 103.83, 123.47, 164.81]], soft=False)
    else:
        main()
