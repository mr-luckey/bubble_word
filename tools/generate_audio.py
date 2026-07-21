#!/usr/bin/env python3
"""Generate lightweight WAV assets for BubbleWord."""

import math
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
SAMPLE_RATE = 44100


def write_wav(path: Path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames.extend(struct.pack("<h", int(v * 32767)))
        wf.writeframes(frames)


def tone(freq, duration, volume=0.35, fade=0.02):
    n = int(SAMPLE_RATE * duration)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = 1.0
        if t < fade:
            env = t / fade
        elif t > duration - fade:
            env = max(0.0, (duration - t) / fade)
        out.append(volume * env * math.sin(2 * math.pi * freq * t))
    return out


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for tr in tracks:
        for i, v in enumerate(tr):
            out[i] += v
    peak = max(abs(v) for v in out) or 1.0
    if peak > 0.95:
        out = [v * (0.95 / peak) for v in out]
    return out


def merge_sfx():
    a = tone(440, 0.08, 0.28)
    b = tone(660, 0.1, 0.24)
    return mix(a + [0.0] * (len(b) - len(a)), [0.0] * (len(a) - len(b)) + b if len(b) > len(a) else b)


def wrong_sfx():
    return mix(tone(180, 0.12, 0.35), tone(140, 0.18, 0.28))


def word_complete_sfx():
    seq = []
    for f in [523, 659, 784]:
        seq.extend(tone(f, 0.09, 0.26))
        seq.extend([0.0] * int(SAMPLE_RATE * 0.015))
    return seq


def win_sfx():
    seq = []
    for f in [523, 659, 784, 1047]:
        seq.extend(tone(f, 0.11, 0.22))
        seq.extend([0.0] * int(SAMPLE_RATE * 0.02))
    return seq


def timeout_sfx():
    seq = []
    for f in [440, 330, 220]:
        seq.extend(tone(f, 0.14, 0.3))
        seq.extend([0.0] * int(SAMPLE_RATE * 0.03))
    return seq


def fail_sfx():
    return mix(tone(220, 0.25, 0.32), tone(165, 0.35, 0.24))


def pop_sfx():
    return tone(880, 0.05, 0.18, fade=0.01)


def bgm_loop():
    # 8-second mellow neon loop (C major pentatonic arpeggio + pad)
    duration = 8.0
    n = int(SAMPLE_RATE * duration)
    notes = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63]
    out = [0.0] * n
    step = int(SAMPLE_RATE * 0.55)
    for i, freq in enumerate(notes * 3):
        start = i * step
        if start >= n:
            break
        chunk = tone(freq, 0.45, 0.08, fade=0.08)
        for j, v in enumerate(chunk):
            idx = start + j
            if idx < n:
                out[idx] += v
    pad = tone(130.81, duration, 0.05, fade=0.4)
    return mix(out, pad)


def main():
    write_wav(OUT / "merge.wav", merge_sfx())
    write_wav(OUT / "wrong.wav", wrong_sfx())
    write_wav(OUT / "word_complete.wav", word_complete_sfx())
    write_wav(OUT / "win.wav", win_sfx())
    write_wav(OUT / "timeout.wav", timeout_sfx())
    write_wav(OUT / "fail.wav", fail_sfx())
    write_wav(OUT / "pop.wav", pop_sfx())
    write_wav(OUT / "bgm.wav", bgm_loop())
    print(f"Generated audio in {OUT}")


if __name__ == "__main__":
    main()
