#!/usr/bin/env python3
"""Generate original, royalty-free ambient demo tracks for MuseFlow.

Everything is synthesised from scratch with numpy so the app ships with a
playable offline catalogue instead of silent placeholders.
"""
import subprocess
from pathlib import Path

import numpy as np

SR = 32000
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)


def note(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def adsr(n, attack, release, curve=1.6):
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    env = np.ones(n, dtype=np.float64)
    env[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** curve
    tail = np.cos(np.linspace(0, np.pi / 2, r)) ** curve
    if r < n:
        env[-r:] *= tail
    return env


def pad(notes, dur, gain=0.16):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for idx, midi in enumerate(notes):
        f = note(midi)
        lfo = 0.0012 * np.sin(2 * np.pi * (0.06 + idx * 0.013) * t + idx)
        for h, amp in ((1, 1.0), (2, 0.22), (3, 0.1), (4, 0.045)):
            det = 1 + (idx - 2) * 0.0009
            out += amp * np.sin(2 * np.pi * f * h * det * t + lfo * h) / (h ** 1.3)
    out /= max(1, len(notes)) ** 0.8
    env = adsr(n, min(2.4, dur * 0.25), min(2.8, dur * 0.35), 2.2)
    return out * env * gain


def bass(midi, dur, gain=0.22):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note(midi)
    sig = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2 * t)
    env = adsr(n, 0.06, min(0.5, dur * 0.3), 3.0)
    return sig * env * gain


def pluck(midi, dur, gain=0.2, bright=0.35):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note(midi)
    sig = (
        np.sin(2 * np.pi * f * t)
        + bright * np.sin(2 * np.pi * f * 2.004 * t)
        + bright * 0.35 * np.sin(2 * np.pi * f * 3.998 * t)
    )
    env = np.exp(-t / (dur * 0.42)) * adsr(n, 0.004, 0.08, 2.0)
    return sig * env * gain


def pluck_pattern(chord, bars, bpm, gain=0.16, pattern=None, octave=12, pan=0.35):
    beat = 60.0 / bpm
    step = beat / 2  # eighth notes
    n_total = int(bars * 4 * beat * SR)
    left = np.zeros(n_total)
    right = np.zeros(n_total)
    p = pattern or [0, 2, 1, 3, 2, 1, 3, 0]
    i = 0
    pos = 0.0
    while pos < bars * 4 * beat - 0.2:
        idx = p[i % len(p)]
        midi = chord[idx % len(chord)] + octave + (12 if (i // len(p)) % 2 else 0)
        sig = pluck(midi, min(2.2, step * 4), gain)
        start = int(pos * SR)
        end = min(n_total, start + len(sig))
        if end > start:
            left[start:end] += sig[: end - start] * (1 - pan * (i % 2))
            right[start:end] += sig[: end - start] * (1 - pan * ((i + 1) % 2))
        pos += step
        i += 1
    return left, right


def kick(dur=0.5, gain=0.4):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = 54 + 70 * np.exp(-t * 18)
    phase = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(phase) * np.exp(-t * 9) * gain


def hat(dur=0.09, gain=0.08):
    n = int(dur * SR)
    t = np.arange(n) / SR
    noise = np.random.default_rng(7).standard_normal(n)
    noise = np.diff(np.concatenate([[0], noise]))
    return noise * np.exp(-t * 45) * gain


def drums(n_total, bpm, style, gain=1.0):
    beat = 60.0 / bpm
    out = np.zeros(n_total)
    b = 0
    while b * beat < n_total / SR:
        t0 = b * beat
        if style != "ambient" and b % 4 in (0, 2):
            k = kick(gain=0.30 * gain)
            i = int(t0 * SR)
            e = min(n_total, i + len(k))
            out[i:e] += k[: e - i]
        if style in ("lofi", "synthwave", "electronic") and b % 4 in (1, 3):
            s = hat(gain=0.05 * gain)
            i = int(t0 * SR)
            e = min(n_total, i + len(s))
            out[i:e] += s[: e - i]
        if style in ("lofi", "electronic") and b % 2 == 0:
            s = hat(gain=0.035 * gain)
            i = int((t0 + beat / 2) * SR)
            e = min(n_total, i + len(s))
            out[i:e] += s[: e - i]
        b += 1
    return out


def reverb(sig, decay=0.32, mix=0.28, seed=3):
    rng = np.random.default_rng(seed)
    n_ir = int(min(2.0, 1.4) * SR)
    t = np.arange(n_ir) / SR
    ir = rng.standard_normal(n_ir) * np.exp(-t / decay)
    ir[: int(0.015 * SR)] *= np.linspace(0, 1, int(0.015 * SR))
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    size = 1
    while size < len(sig) + n_ir:
        size *= 2
    wet = np.fft.irfft(np.fft.rfft(sig, size) * np.fft.rfft(ir, size))[: len(sig)]
    return sig * (1 - mix) + wet * mix * 1.4


def lowpass_noise(n, gain=0.012, seed=11):
    rng = np.random.default_rng(seed)
    noise = rng.standard_normal(n)
    a = 0.995
    out = np.empty(n)
    acc = 0.0
    for i in range(0, n, 4096):
        chunk = noise[i : i + 4096]
        filtered = np.empty(len(chunk))
        for j, v in enumerate(chunk):
            acc = a * acc + (1 - a) * v
            filtered[j] = acc
        out[i : i + 4096] = filtered
    return out * gain


TRACKS = [
    dict(name="Tides", bpm=92, bars=16, style="ambient", chords=[
        [57, 60, 64, 67, 71], [53, 57, 60, 64], [48, 52, 55, 59], [55, 59, 62, 64]]),
    dict(name="Night Flight", bpm=100, bars=16, style="lofi", chords=[
        [54, 57, 61, 64], [50, 54, 57, 61], [45, 49, 52, 56], [52, 56, 59, 62]]),
    dict(name="Glass Sea", bpm=72, bars=12, style="ambient", chords=[
        [50, 54, 57, 61, 64], [47, 50, 54, 57], [43, 47, 50, 54], [45, 49, 52, 55, 59]]),
    dict(name="Aurora Letters", bpm=86, bars=16, style="ambient", chords=[
        [49, 52, 56, 59], [45, 49, 52, 56], [40, 44, 47, 52], [47, 51, 54, 57]]),
    dict(name="Neon Rain", bpm=110, bars=16, style="synthwave", chords=[
        [43, 46, 50, 53], [39, 43, 46, 50], [46, 50, 53, 57], [41, 45, 48, 52]]),
    dict(name="Slow Planet", bpm=70, bars=12, style="lofi", chords=[
        [52, 56, 59, 63], [49, 52, 56, 59], [45, 49, 52, 56], [47, 51, 54, 57]]),
    dict(name="Morning Mist", bpm=80, bars=16, style="ambient", chords=[
        [55, 59, 62, 66], [52, 55, 59, 62], [48, 52, 55, 59], [50, 54, 57, 62]]),
    dict(name="Zero-G", bpm=118, bars=20, style="electronic", chords=[
        [47, 50, 54, 57], [43, 47, 50, 54], [38, 42, 45, 50], [45, 49, 52, 55]]),
]

GAINS = [0.9, 0.85, 0.8, 0.88, 0.82, 0.8, 0.75, 0.9]
LYRIC_HOOKS = {}


def render_track(spec, idx):
    bpm = spec["bpm"]
    bars = spec["bars"]
    beat = 60.0 / bpm
    total = bars * 4 * beat + 3.0
    n = int(total * SR)
    chords = spec["chords"]
    bar_chords = []
    per = max(1, bars // len(chords))
    for ci, ch in enumerate(chords):
        bar_chords += [ch] * per
    bar_chords = (bar_chords + [chords[-1]] * bars)[:bars]

    left = np.zeros(n)
    right = np.zeros(n)
    for bar in range(bars):
        ch = bar_chords[bar]
        seg = beat * 4
        start = int(bar * seg * SR)
        end = min(n, start + int(seg * SR))
        p = pad(ch, seg + 0.8, gain=0.15)
        p2 = pad(ch, seg + 0.8, gain=0.15)
        m = end - start
        left[start:end] += p[:m] * 0.95
        right[start:end] += p2[:m] * 0.95
        b = bass(ch[0] - 24, seg, gain=0.16)
        left[start:end] += b[:m]
        right[start:end] += b[:m]

    ap_l, ap_r = pluck_pattern(chords[0], bars, bpm, gain=0.10, octave=12, pan=0.5)
    m = min(len(ap_l), n)
    left[:m] += ap_l[:m]
    right[:m] += ap_r[:m]

    if spec["style"] != "ambient":
        d = drums(n, bpm, spec["style"], gain=GAINS[idx])
        left += d * 0.7
        right += d * 0.7
    if spec["style"] == "lofi":
        nz = lowpass_noise(n, gain=0.02, seed=idx + 20)
        left += nz
        right += nz * 0.9
    if spec["style"] == "synthwave":
        shimmer = pad([chords[0][i] + 24 for i in range(len(chords[0]))], total, gain=0.03)
        left += shimmer * 0.6
        right += shimmer * 0.5

    left = reverb(left, decay=0.35 + 0.02 * idx, mix=0.3, seed=idx + 1)
    right = reverb(right, decay=0.35 + 0.02 * idx, mix=0.3, seed=idx + 101)

    fade = int(2.5 * SR)
    env = np.ones(n)
    env[:fade] = np.linspace(0, 1, fade) ** 1.4
    env[-fade:] *= np.linspace(1, 0, fade) ** 1.4
    left *= env
    right *= env
    peak = max(np.abs(left).max(), np.abs(right).max(), 1e-9)
    norm = 0.89 / peak
    stereo = np.stack([left * norm, right * norm], axis=1)
    stereo = np.tanh(stereo * 1.05) * 0.98
    pcm = (stereo * 32767).astype(np.int16)

    import wave
    wav_path = OUT / f"demo_{idx+1:02d}.wav"
    with wave.open(str(wav_path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())

    mp3_path = OUT / f"demo_{idx+1:02d}.mp3"
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav_path),
         "-codec:a", "libmp3lame", "-b:a", "160k", "-ar", "44100", str(mp3_path)],
        check=True,
    )
    wav_path.unlink()
    print(f"{spec['name']}: {total:.1f}s -> {mp3_path.name} {mp3_path.stat().st_size/1024:.0f}KB")


if __name__ == "__main__":
    for i, spec in enumerate(TRACKS):
        render_track(spec, i)
