#!/usr/bin/env python3
"""Write the story example's music, tune.wav: a short calm loop made here (no samples),
then encoded for the mod with
  ffmpeg -y -i tune.wav -ar 22050 -ac 1 -b:a 48k tune.mp3
(Flash embeds MP3 at 11025, 22050 or 44100 Hz.)"""
import array
import math
import wave

RATE = 22050
BEAT = 0.42  # seconds
# A pentatonic line over a soft drone: (semitones from A3, beats); None is a rest.
MELODY = [(7, 1), (9, 1), (12, 2), (9, 1), (7, 1), (4, 2),
          (2, 1), (4, 1), (7, 2), (4, 1), (2, 1), (0, 2),
          (7, 1), (9, 1), (12, 1), (14, 1), (12, 2), (9, 2),
          (7, 1), (4, 1), (2, 1), (4, 1), (0, 4)]
total = sum(b for _, b in MELODY) * BEAT
n = int(total * RATE)
out = array.array("h", [0] * n)


def note(freq, start, length, amp):
    a, d = 0.02, length
    for i in range(int(start * RATE), min(n, int((start + length) * RATE))):
        t = i / RATE - start
        env = min(1.0, t / a) * math.exp(-2.6 * t / d)
        s = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t)
        out[i] = max(-32767, min(32767, out[i] + int(amp * env * s)))


t = 0.0
for semi, beats in MELODY:
    if semi is not None:
        note(220 * 2 ** ((semi + 12) / 12), t, beats * BEAT * 1.6, 5200)
    t += beats * BEAT
# The drone: A2 and E3, faded in and out so the loop joins.
for i in range(n):
    x = i / RATE
    fade = min(1.0, x / 1.5, (total - x) / 1.5)
    s = 0.6 * math.sin(2 * math.pi * 110 * x) + 0.4 * math.sin(2 * math.pi * 164.81 * x)
    out[i] = max(-32767, min(32767, out[i] + int(1800 * fade * s)))
with wave.open("tune.wav", "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(out.tobytes())
print(f"tune.wav: {total:.1f} s")
