#!/usr/bin/env python3
"""Generates all of the game's sound as original, synthesised WAV files.
Needs numpy. Output: assets/audio/*.wav (mono, 16-bit, 22050 Hz)."""
import os, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def save(name, x, peak=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((x * 32767).astype(np.int16).tobytes())


def t(sec):
    return np.arange(int(SR * sec)) / SR


def lowpass(x, alpha):
    y = np.empty_like(x); acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc); y[i] = acc
    return y


def highpass(x, alpha):
    return x - lowpass(x, alpha)


def env(n, attack, decay):
    i = np.arange(n) / SR
    return np.minimum(i / max(attack, 1e-4), 1.0) * np.exp(-i / decay)


def tone(freq, sec, attack=0.005, decay=0.3, harmonics=(1.0, 0.4, 0.2, 0.08)):
    x = t(sec); y = np.zeros_like(x)
    for k, a in enumerate(harmonics, 1):
        y += a * np.sin(2 * np.pi * freq * k * x)
    return y * env(len(x), attack, decay)


def seamless(x, fade):
    """Cross-fades the tail into the head so the clip loops without a click."""
    n = int(SR * fade)
    w = np.linspace(0, 1, n)
    head = x[:n] * w + x[-n:] * (1 - w)
    return np.concatenate([head, x[n:-n]])


def place(buf, clip, at):
    i = int(at * SR); n = min(len(clip), len(buf) - i)
    if n > 0:
        buf[i:i + n] += clip[:n]


# ---- interface sounds
save("click", highpass(rng.normal(size=int(SR * 0.05)), 0.4) * env(int(SR * 0.05), 0.001, 0.008) + tone(1400, 0.05, 0.001, 0.01) * 0.5, 0.5)
n = int(SR * 0.32)
paper = highpass(rng.normal(size=n), 0.25) * (0.4 + 0.6 * np.abs(np.sin(np.linspace(0, 9, n)))) * env(n, 0.03, 0.12)
save("paper", paper, 0.55)
found = np.zeros(int(SR * 0.9)); place(found, tone(659.3, 0.6, decay=0.22), 0.0); place(found, tone(880.0, 0.8, decay=0.3), 0.12)
save("found", found, 0.6)
ins = np.zeros(int(SR * 1.6))
for i, f in enumerate((523.3, 659.3, 784.0, 1046.5)):
    place(ins, tone(f, 1.2, decay=0.45, harmonics=(1.0, 0.25, 0.1)), i * 0.11)
save("insight", ins, 0.6)
wr = tone(98, 0.45, 0.005, 0.14, (1.0, 0.6, 0.5, 0.3)) + tone(92.5, 0.45, 0.005, 0.14, (1.0, 0.6, 0.5, 0.3))
save("wrong", wr, 0.6)
n = int(SR * 0.5)
stamp = lowpass(rng.normal(size=n), 0.08) * env(n, 0.001, 0.05) * 3 + tone(70, 0.5, 0.001, 0.09, (1.0, 0.5))
save("stamp", stamp, 0.9)
step = np.zeros(int(SR * 0.7))
for i in range(2):
    k = int(SR * 0.12); place(step, lowpass(rng.normal(size=k), 0.12) * env(k, 0.002, 0.03), i * 0.3)
save("step", step, 0.6)

# ---- rain loop (lobby, offices)
sec = 9.0; n = int(SR * sec)
hiss = highpass(lowpass(rng.normal(size=n), 0.5), 0.05)
swell = 0.8 + 0.2 * np.sin(2 * np.pi * t(sec) / sec * 2 + 1.0)
rain = hiss * swell * 0.5
for _ in range(260):                       # individual drops on the glass
    k = int(SR * 0.012)
    place(rain, highpass(rng.normal(size=k), 0.6) * env(k, 0.0005, 0.003) * rng.uniform(0.3, 1.0), rng.uniform(0, sec - 0.1))
save("rain", seamless(rain, 0.8), 0.45)

# ---- basement loop (stacks): low hum, ventilation, a slow drip
sec = 10.0; n = int(SR * sec); x = t(sec)
hum = 0.5 * np.sin(2 * np.pi * 50 * x) + 0.25 * np.sin(2 * np.pi * 100 * x + 0.3) + 0.1 * np.sin(2 * np.pi * 150 * x)
vent = lowpass(rng.normal(size=n), 0.02) * 2.5
base = hum * 0.35 + vent
for at in (1.3, 4.9, 8.2):
    place(base, tone(1250, 0.5, 0.001, 0.05, (1.0, 0.3)) * 0.35, at)
    place(base, tone(940, 0.5, 0.001, 0.07, (1.0, 0.3)) * 0.2, at + 0.05)
save("basement", seamless(base, 1.0), 0.4)

# ---- music: slow noir theme in D minor, soft electric-piano tones over a pad
BPM = 56; beat = 60 / BPM; bars = 16; sec = bars * 4 * beat; n = int(SR * sec)
mus = np.zeros(n + SR * 4)
N = {"D2": 73.42, "A2": 110.0, "Bb2": 116.54, "G2": 98.0, "C3": 130.81, "D3": 146.83, "F3": 174.61, "A3": 220.0, "Bb3": 233.08,
     "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.0, "A4": 440.0, "Bb4": 466.16, "C5": 523.25, "D5": 587.33}
chords = [("D2", ["D3", "F3", "A3"]), ("Bb2", ["D3", "F3", "Bb3"]), ("G2", ["D3", "G4", "Bb3"]), ("A2", ["C4", "E4", "A3"])] * 4
melody = [  # (bar, beat, note, beats)
    (0, 0, "A4", 2), (0, 2.5, "F4", 1), (1, 0, "D4", 3), (2, 0, "G4", 1.5), (2, 2, "Bb4", 1.5), (3, 0, "A4", 2), (3, 2.5, "E4", 1.5),
    (4, 0, "F4", 2), (4, 2, "A4", 2), (5, 0, "D5", 3), (6, 1, "Bb4", 1), (6, 2, "G4", 2), (7, 0, "A4", 4),
    (8, 0.5, "D4", 1), (8, 2, "F4", 2), (9, 0, "Bb4", 2.5), (10, 0, "G4", 1), (10, 1.5, "D4", 2), (11, 0, "E4", 3),
    (12, 0, "A4", 1.5), (12, 2, "C5", 2), (13, 0, "D5", 2), (13, 2.5, "Bb4", 1.5), (14, 0, "G4", 3), (15, 0, "A4", 2), (15, 2, "D4", 2)]
for b, (root, notes) in enumerate(chords):
    at = b * 4 * beat
    place(mus, tone(N[root], 4 * beat + 1.5, 0.4, 2.2, (1.0, 0.3, 0.1)) * 0.55, at)
    for k, nm in enumerate(notes):
        pad = tone(N[nm], 4 * beat + 2.0, 1.2, 2.6, (1.0, 0.15)) * 0.16
        place(mus, pad, at)
        place(mus, tone(N[nm], 2.0, 0.01, 0.7, (1.0, 0.35, 0.12)) * 0.13, at + (1 + k) * beat * 0.75)
for (b, bt, nm, ln) in melody:
    place(mus, tone(N[nm], ln * beat + 1.6, 0.012, 0.9, (1.0, 0.45, 0.15, 0.05)) * 0.34, (b * 4 + bt) * beat)
# fold the ringing tail back onto the start so the loop is seamless
mus[:SR * 4] += mus[n:n + SR * 4]
mus = lowpass(mus[:n], 0.35)
save("music", mus, 0.7)
print("audio written to assets/audio/")
