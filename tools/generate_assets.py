#!/usr/bin/env python3
"""Original asset generator for BLACK SITE.

Generates grungy institutional textures, the title logo, atmospheric sprites,
and a restrained set of synthesized sound effects. No third-party art is used.
"""
from __future__ import annotations

import math
import random
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
TEX = ROOT / "assets" / "textures"
AUD = ROOT / "assets" / "audio"
TEX.mkdir(parents=True, exist_ok=True)
AUD.mkdir(parents=True, exist_ok=True)
random.seed(1906)
np.random.seed(1906)

FONT_DIR = Path("C:/Windows/Fonts")


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(FONT_DIR / name), size)
    except Exception:
        return ImageFont.load_default()


def noise_image(w: int, h: int, amount: int = 22) -> Image.Image:
    arr = np.random.normal(128, amount, (h, w, 1)).repeat(3, axis=2)
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGB")


def add_grain(img: Image.Image, amount: int = 12, seed: int = 0) -> Image.Image:
    rng = np.random.default_rng(seed)
    arr = np.asarray(img.convert("RGB"), dtype=np.int16)
    n = rng.normal(0, amount, arr.shape[:2])[:, :, None]
    arr = np.clip(arr + n, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGB")


def soft_ellipse(draw: ImageDraw.ImageDraw, box, color, blur=0):
    layer = Image.new("RGBA", draw._image.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse(box, fill=color)
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    draw._image.alpha_composite(layer)


def make_floor_checker() -> Image.Image:
    size = 512
    cells = 4
    cs = size // cells
    img = Image.new("RGB", (size, size), (91, 98, 86))
    d = ImageDraw.Draw(img)
    colors = [(112, 124, 109), (154, 152, 134)]
    for y in range(cells):
        for x in range(cells):
            base = colors[(x + y) % 2]
            jitter = random.randint(-7, 7)
            col = tuple(max(0, min(255, c + jitter)) for c in base)
            d.rectangle([x * cs, y * cs, (x + 1) * cs, (y + 1) * cs], fill=col)
            # chipped inner border
            for _ in range(7):
                cx = x * cs + random.randint(6, cs - 6)
                cy = y * cs + random.randint(6, cs - 6)
                r = random.randint(1, 4)
                d.ellipse([cx - r, cy - r, cx + r, cy + r],
                          fill=(random.randint(70, 110), random.randint(75, 110), random.randint(68, 100)))
    # grout
    for i in range(cells + 1):
        p = i * cs
        d.line([(p, 0), (p, size)], fill=(56, 60, 53), width=5)
        d.line([(0, p), (size, p)], fill=(56, 60, 53), width=5)
    img = add_grain(img, 17, 3)

    # grime layer
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(layer)
    for _ in range(38):
        x, y = random.randint(0, size), random.randint(0, size)
        rw, rh = random.randint(10, 85), random.randint(5, 45)
        alpha = random.randint(16, 65)
        gd.ellipse([x - rw, y - rh, x + rw, y + rh],
                   fill=(35, 38, 30, alpha))
    for _ in range(20):
        x, y = random.randint(0, size), random.randint(0, size)
        gd.line([(x, y), (x + random.randint(-35, 35), y + random.randint(15, 100))],
                fill=(24, 26, 21, random.randint(18, 55)), width=random.randint(1, 5))
    # fine cracks
    for _ in range(6):
        x, y = random.randint(20, size - 20), random.randint(20, size - 20)
        pts = [(x, y)]
        for _i in range(5):
            x += random.randint(-30, 30)
            y += random.randint(4, 36)
            pts.append((x, y))
        gd.line(pts, fill=(26, 28, 24, 140), width=2)
    layer = layer.filter(ImageFilter.GaussianBlur(1.3))
    img = Image.alpha_composite(img.convert("RGBA"), layer)
    return add_grain(img.convert("RGB"), 7, 4)


def make_concrete(name: str, base=(75, 76, 70), seed=9) -> Image.Image:
    size = 512
    rng = np.random.default_rng(seed)
    n = rng.normal(0, 1, (size, size))
    n = (n - n.min()) / (n.max() - n.min())
    arr = np.zeros((size, size, 3), dtype=np.float32)
    for c, b in enumerate(base):
        arr[:, :, c] = b + (n - .5) * 35
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(layer)
    for _ in range(42):
        x, y = random.randint(0, size), random.randint(0, size)
        rw, rh = random.randint(8, 110), random.randint(4, 65)
        gd.ellipse([x - rw, y - rh, x + rw, y + rh],
                   fill=(30, 31, 28, random.randint(8, 42)))
    for _ in range(8):
        x, y = random.randint(10, size - 10), random.randint(10, size - 10)
        pts = [(x, y)]
        for _i in range(7):
            x += random.randint(-22, 22)
            y += random.randint(12, 48)
            pts.append((x, y))
        gd.line(pts, fill=(25, 25, 23, 105), width=random.randint(1, 3))
    layer = layer.filter(ImageFilter.GaussianBlur(1.4))
    img = Image.alpha_composite(img.convert("RGBA"), layer)
    return add_grain(img.convert("RGB"), 8, seed)


def make_wall_plaster() -> Image.Image:
    size = 512
    img = Image.new("RGB", (size, size), (124, 124, 109))
    d = ImageDraw.Draw(img)
    for _ in range(1600):
        x, y = random.randint(0, size), random.randint(0, size)
        r = random.randint(1, 8)
        v = random.randint(-28, 25)
        c = tuple(max(0, min(255, 124 + v + random.randint(-5, 5))) for _ in range(3))
        d.ellipse([x - r, y - r, x + r, y + r], fill=c)
    # exposed plaster / mold
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for _ in range(26):
        x, y = random.randint(0, size), random.randint(0, size)
        w = random.randint(18, 95)
        h = random.randint(10, 80)
        color = random.choice([(53, 56, 48, 55), (86, 93, 72, 55), (55, 45, 38, 45)])
        ld.ellipse([x, y, x + w, y + h], fill=color)
    for _ in range(15):
        x = random.randint(0, size)
        y = random.randint(0, size)
        ld.line([(x, y), (x + random.randint(-15, 20), y + random.randint(40, 170))],
                fill=(69, 67, 51, random.randint(18, 46)), width=random.randint(2, 12))
    layer = layer.filter(ImageFilter.GaussianBlur(5))
    img = Image.alpha_composite(img.convert("RGBA"), layer)
    d = ImageDraw.Draw(img)
    # cracks
    for _ in range(9):
        x, y = random.randint(20, size - 20), random.randint(20, size - 20)
        pts = [(x, y)]
        for _i in range(8):
            x += random.randint(-18, 18)
            y += random.randint(9, 40)
            pts.append((x, y))
        d.line(pts, fill=(61, 58, 49), width=2)
        d.line(pts, fill=(153, 150, 134), width=1)
    # peeling wall base
    peel = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pd = ImageDraw.Draw(peel)
    for _ in range(16):
        x = random.randint(0, size)
        y = random.randint(size - 130, size)
        pd.polygon([(x, y), (x + random.randint(12, 55), y + random.randint(-4, 14)),
                    (x + random.randint(25, 85), y + random.randint(16, 65)),
                    (x, y + random.randint(20, 90))],
                   fill=(79, 81, 68, random.randint(60, 150)))
    img = Image.alpha_composite(img, peel)
    return add_grain(img.convert("RGB"), 8, 10)


def make_wall_tile() -> Image.Image:
    size = 512
    img = Image.new("RGB", (size, size), (52, 63, 54))
    d = ImageDraw.Draw(img)
    tw, th = 64, 85
    for y in range(0, size, th):
        for x in range(-32 if (y // th) % 2 else 0, size, tw):
            col = random.choice([(77, 98, 83), (82, 103, 88), (70, 89, 75), (88, 107, 91)])
            d.rectangle([x + 3, y + 3, x + tw - 3, y + th - 3], fill=col)
            d.line([(x + 3, y + 5), (x + tw - 3, y + 5)], fill=(118, 133, 114), width=2)
    for _ in range(20):
        x, y = random.randint(0, size), random.randint(0, size)
        r = random.randint(10, 50)
        d.ellipse([x, y, x + r, y + r], fill=(49, 61, 48))
    for _ in range(6):
        x, y = random.randint(0, size), random.randint(0, size)
        d.ellipse([x, y, x + random.randint(5, 18), y + random.randint(6, 30)], fill=(88, 78, 62))
    img = add_grain(img, 12, 11)
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for _ in range(30):
        x = random.randint(0, size)
        od.line([(x, 0), (x + random.randint(-8, 8), size)],
                fill=(30, 37, 29, random.randint(8, 30)), width=random.randint(1, 5))
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


def make_wood() -> Image.Image:
    size = 512
    img = Image.new("RGB", (size, size), (58, 43, 31))
    d = ImageDraw.Draw(img)
    for x in range(0, size, 64):
        shade = random.randint(-12, 12)
        d.rectangle([x, 0, x + 64, size], fill=(60 + shade, 44 + shade, 31 + shade))
        d.line([(x, 0), (x, size)], fill=(28, 21, 17), width=4)
        for _ in range(20):
            gx = x + random.randint(4, 60)
            pts = [(gx, 0)]
            for y in range(0, size, 64):
                pts.append((gx + random.randint(-4, 4), y + 64))
            d.line(pts, fill=(42 + random.randint(-6, 8), 31, 22, 100), width=random.randint(1, 3))
    img = add_grain(img, 9, 12)
    return img


def make_metal() -> Image.Image:
    size = 512
    img = make_concrete("metal", (74, 76, 72), 13)
    d = ImageDraw.Draw(img)
    for _ in range(28):
        x = random.randint(0, size)
        y = random.randint(0, size)
        d.line([(x, y), (x + random.randint(-20, 20), y + random.randint(15, 70))],
               fill=(118, 70, 40), width=random.randint(1, 9))
    for _ in range(70):
        x, y = random.randint(0, size), random.randint(0, size)
        d.ellipse([x, y, x + random.randint(1, 5), y + random.randint(1, 5)], fill=(151, 91, 50))
    return add_grain(img, 7, 14)


def make_grass() -> Image.Image:
    size = 512
    rng = np.random.default_rng(33)
    base = np.zeros((size, size, 3), dtype=np.float32)
    n = rng.normal(0, 1, (size, size))
    n = (n - n.min()) / (n.max() - n.min())
    base[:, :, 0] = 51 + n * 20
    base[:, :, 1] = 75 + n * 35
    base[:, :, 2] = 45 + n * 19
    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    for _ in range(1200):
        x, y = random.randint(0, size), random.randint(0, size)
        d.line([(x, y), (x + random.randint(-3, 3), y - random.randint(2, 9))],
               fill=(random.randint(39, 82), random.randint(60, 110), random.randint(34, 65)), width=1)
    return add_grain(img, 5, 34)


def make_logo() -> Image.Image:
    w, h = 1500, 430
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = font("bahnschrift.ttf", 196)
    text = "BLACK SITE"
    tracking = 28
    widths = [d.textbbox((0, 0), ch, font=f)[2] for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = (w - total) // 2
    y = 64
    for i, ch in enumerate(text):
        # Off-white, with a faint rust offset for print misregistration.
        d.text((x + 2, y + 2), ch, font=f, fill=(92, 32, 25, 180))
        d.text((x, y), ch, font=f, fill=(220, 218, 202, 245))
        x += widths[i] + tracking
    # tagline
    f2 = font("consola.ttf", 26)
    tag = "S I T E   0 6   /   I N T A K E"
    tw = d.textbbox((0, 0), tag, font=f2)[2]
    d.text(((w - tw) // 2, 292), tag, font=f2, fill=(142, 146, 128, 220))
    d.line([(w // 2 - 330, 344), (w // 2 + 330, 344)], fill=(120, 39, 32, 200), width=3)
    f3 = font("consola.ttf", 17)
    tag2 = "Y O U   A L W A Y S   C O M E   B A C K"
    tw2 = d.textbbox((0, 0), tag2, font=f3)[2]
    d.text(((w - tw2) // 2, 366), tag2, font=f3, fill=(112, 111, 99, 190))

    # Distress / broken ink: subtract alpha with scratches and dots.
    alpha = np.array(img.getchannel("A"))
    rng = np.random.default_rng(1906)
    for _ in range(140):
        x0 = rng.integers(0, w)
        y0 = rng.integers(0, 300)
        length = rng.integers(5, 140)
        th = rng.integers(0, 3)
        alpha[y0:y0 + th + 1, max(0, x0 - length // 2):min(w, x0 + length // 2)] = np.maximum(
            0, alpha[y0:y0 + th + 1, max(0, x0 - length // 2):min(w, x0 + length // 2)] - rng.integers(60, 170)
        )
    for _ in range(1800):
        x0 = rng.integers(0, w)
        y0 = rng.integers(0, 320)
        alpha[y0:y0 + 2, x0:x0 + 2] = 0
    img.putalpha(Image.fromarray(alpha))
    return img


def make_ghost() -> Image.Image:
    w, h = 256, 384
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    # silhouette head, shoulders, trailing gown
    gd.ellipse((83, 24, 173, 128), fill=(210, 240, 238, 105))
    gd.rounded_rectangle((70, 94, 186, 264), radius=50, fill=(205, 238, 235, 92))
    gd.polygon([(70, 226), (186, 226), (204, 350), (154, 323), (127, 365), (101, 322), (51, 349)],
               fill=(202, 235, 232, 75))
    gd.ellipse((102, 92, 154, 150), fill=(226, 252, 249, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(16))
    img.alpha_composite(glow)
    body = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.ellipse((92, 35, 164, 124), fill=(224, 247, 244, 155))
    bd.rounded_rectangle((83, 108, 173, 260), radius=38, fill=(217, 243, 240, 135))
    bd.polygon([(83, 225), (173, 225), (188, 333), (145, 307), (126, 348), (105, 307), (68, 334)],
               fill=(214, 241, 238, 112))
    bd.ellipse((112, 76, 126, 92), fill=(19, 25, 24, 100))
    bd.ellipse((138, 76, 152, 92), fill=(19, 25, 24, 100))
    body = body.filter(ImageFilter.GaussianBlur(1.2))
    img.alpha_composite(body)
    return img


def make_scrawl(text: str, name: str, color=(201, 203, 186, 205), size=(1024, 256)) -> None:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = font("georgiab.ttf", 94)
    lines = text.split("\n")
    y = 25
    for line in lines:
        d.text((26, y), line, font=f, fill=color)
        d.text((23, y), line, font=f, fill=(color[0], color[1], color[2], color[3] - 70))
        y += 110
    # scratch away bits
    a = np.array(img.getchannel("A"))
    rng = np.random.default_rng(len(text))
    for _ in range(600):
        x = rng.integers(0, size[0])
        yy = rng.integers(0, size[1])
        a[yy:yy + rng.integers(1, 3), x:x + rng.integers(1, 5)] = 0
    img.putalpha(Image.fromarray(a))
    img.save(TEX / name)


def rms_norm(x: np.ndarray, peak=0.5) -> np.ndarray:
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    return (x / m) * peak


def write_wav(name: str, samples: np.ndarray, sr: int = 22050) -> None:
    samples = np.clip(samples, -1, 1)
    pcm = (samples * 32767).astype("<i2")
    with wave.open(str(AUD / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(pcm.tobytes())


def env_adsr(n: int, a=0.01, d=0.1, s=0.6, r=0.2, sr=22050) -> np.ndarray:
    a_n, d_n, r_n = int(a * sr), int(d * sr), int(r * sr)
    s_n = max(0, n - a_n - d_n - r_n)
    return np.concatenate([
        np.linspace(0, 1, max(1, a_n)),
        np.linspace(1, s, max(1, d_n)),
        np.full(s_n, s),
        np.linspace(s, 0, max(1, r_n)),
    ])[:n]


def lowpass_noise(n: int, cutoff=0.06) -> np.ndarray:
    x = np.random.randn(n)
    out = np.zeros(n)
    v = 0.0
    for i in range(n):
        v += cutoff * (x[i] - v)
        out[i] = v
    return out


def make_audio() -> None:
    sr = 22050

    def t(duration):
        return np.arange(int(sr * duration)) / sr

    # --- ambience: asylum ---
    def loopify(sig, fade_s):
        fade_n = int(fade_s * sr)
        w = np.linspace(0, 1, fade_n)
        sig[:fade_n] = sig[:fade_n] * w + sig[-fade_n:] * (1 - w)
        return sig[:-fade_n]

    def add_tone(buf, start_s, length_s, freq, amp, decay, harmonics):
        i = int(start_s * sr)
        length = min(int(length_s * sr), len(buf) - i)
        if length <= 0:
            return
        ts = np.arange(length) / sr
        env = env_adsr(length, .04, .18, .35, min(.9, length_s * .35), sr)
        s = sum(a * np.sin(2 * np.pi * freq * h * ts + phase)
                for h, a, phase in harmonics)
        buf[i:i + length] += s * env * np.exp(-ts * decay) * amp

    np.random.seed(1906)
    dur = 32.0
    n = int(dur * sr)
    tt = np.arange(n) / sr
    sub = 0.020 * np.sin(2 * np.pi * 36.71 * tt + .30 * np.sin(2 * np.pi * .033 * tt))
    drone = (0.022 * np.sin(2 * np.pi * 73.42 * tt + .55 * np.sin(2 * np.pi * .047 * tt))
             + 0.014 * np.sin(2 * np.pi * 110.0 * tt + .40 * np.sin(2 * np.pi * .061 * tt))
             + 0.008 * np.sin(2 * np.pi * 146.83 * tt + .30 * np.sin(2 * np.pi * .073 * tt)))
    dissonance = (0.009 * np.sin(2 * np.pi * 155.56 * tt)
                  + 0.006 * np.sin(2 * np.pi * 164.81 * tt))
    dissonance *= 0.45 + 0.55 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 13.0))
    room = lowpass_noise(n, 0.0012) * 4.2
    air = lowpass_noise(n, 0.045) * 0.17
    music_box = np.zeros(n)
    for pos, freq in [(1.6, 587.33), (5.8, 698.46), (10.0, 880.0), (14.1, 932.33),
                      (18.7, 698.46), (23.3, 622.25), (27.4, 587.33)]:
        add_tone(music_box, pos, 3.2, freq, .020, 1.5,
                 [(1.0, 1.0, 0.0), (2.005, .22, .3), (3.99, .08, .7)])
    cello = np.zeros(n)
    for pos, freq in [(0.2, 73.42), (8.0, 87.31), (16.0, 110.0), (24.0, 69.30)]:
        add_tone(cello, pos, 8.0, freq, .016, .28,
                 [(1.0, 1.0, 0.0), (2.0, .40, .2), (3.0, .18, .5), (4.0, .08, .9)])
    creak = np.zeros(n)
    for pos in [4.2, 12.8, 21.4, 27.9]:
        i = int(pos * sr)
        cl = min(int(2.1 * sr), n - i)
        tl = np.arange(cl) / sr
        s = 0.020 * np.sin(2 * np.pi * (82 + 31 * np.sin(2 * np.pi * .27 * tl)) * tl)
        s *= env_adsr(cl, .35, .30, .40, .85, sr)
        creak[i:i + cl] += s
    clang = np.zeros(n)
    add_tone(clang, 19.2, 3.5, 211.0, .020, 1.1,
             [(1.0, 1.0, 0.0), (1.64, .55, .4), (2.48, .30, .9)])
    amb = sub + drone + dissonance + room + air + music_box + cello + creak + clang
    amb = loopify(amb, 2.2)
    write_wav("amb_asylum.wav", rms_norm(amb, .44), sr)

    # --- basement ambience ---
    dur = 24.0
    n = int(dur * sr)
    tt = np.arange(n) / sr
    moan = (0.030 * np.sin(2 * np.pi * 37 * tt + .9 * np.sin(2 * np.pi * .055 * tt))
            + 0.015 * np.sin(2 * np.pi * 55 * tt + .4 * np.sin(2 * np.pi * .08 * tt))
            + 0.008 * np.sin(2 * np.pi * 74 * tt))
    metal = 0.007 * np.sin(2 * np.pi * 233 * tt) * (0.25 + 0.75 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 5.7)))
    water = lowpass_noise(n, 0.0007) * 6.5
    whisper = lowpass_noise(n, 0.035) * (0.10 + 0.10 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 3.1)))
    drips = np.zeros(n)
    for pos in [2.9, 7.4, 11.8, 17.2, 21.3]:
        add_tone(drips, pos, 1.1, 1260 + 90 * np.sin(pos), .025, 8.0,
                 [(1.0, 1.0, 0.0), (1.98, .18, .6)])
    impacts = np.zeros(n)
    for pos in [3.6, 13.1, 20.8]:
        i = int(pos * sr)
        length = min(int(2.0 * sr), n - i)
        ts = np.arange(length) / sr
        s = (np.sin(2 * np.pi * 44 * ts) + .25 * np.sin(2 * np.pi * 92 * ts)) * np.exp(-ts * 3.4)
        s *= env_adsr(length, .01, .08, .25, .9, sr) * .020
        impacts[i:i + length] += s
    amb = moan + metal + water + whisper + drips + impacts
    amb = loopify(amb, 1.5)
    write_wav("amb_basement.wav", rms_norm(amb, .40), sr)

    # --- outside ambience / soft music ---
    dur = 28.0
    n = int(dur * sr)
    tt = np.arange(n) / sr
    wind = lowpass_noise(n, 0.006) * 2.5 * (0.6 + 0.2 * np.sin(2 * np.pi * tt / 9))
    birds = np.zeros(n)
    for pos in [2.1, 5.7, 7.2, 13.0, 18.7, 22.1]:
        i = int(pos * sr)
        length = int(.6 * sr)
        tb = np.arange(length) / sr
        f0 = 1500 + np.random.rand() * 1300
        b = np.sin(2 * np.pi * (f0 + 500 * np.sin(2 * np.pi * 6 * tb)) * tb)
        b *= env_adsr(length, .01, .05, .2, .25, sr) * .006
        birds[i:i + length] += b
    music = np.zeros(n)
    notes = [220.0, 277.18, 329.63, 440.0, 329.63, 277.18]
    for i in range(14):
        pos = i * 1.85
        if pos >= dur - 2:
            break
        idx = int(pos * sr)
        length = int(3.0 * sr)
        ts = np.arange(length) / sr
        freq = notes[i % len(notes)]
        tone = (np.sin(2 * np.pi * freq * ts) + .35 * np.sin(2 * np.pi * freq * 2.01 * ts)
                + .11 * np.sin(2 * np.pi * freq * 3.99 * ts))
        tone *= np.exp(-ts * 1.5) * env_adsr(length, .08, .4, .5, 1.2, sr) * .018
        music[idx:idx + length] += tone
    amb = wind * .35 + birds + music
    fade = int(2.5 * sr)
    w = np.linspace(0, 1, fade)
    amb[:fade] = amb[:fade] * w + amb[-fade:] * (1 - w)
    amb = amb[:-fade]
    write_wav("amb_outside.wav", rms_norm(amb, .32), sr)

    # --- footsteps ---
    for i in range(3):
        length = int(.18 * sr)
        tt = np.arange(length) / sr
        noise = lowpass_noise(length, 0.14)
        thud = np.sin(2 * np.pi * (85 - i * 9) * tt) * np.exp(-tt * 28) * .2
        s = noise * np.exp(-tt * 18) * (.25 + .04 * i) + thud
        s += np.random.randn(length) * 0.012
        # tiny grit
        write_wav(f"step_{i+1}.wav", rms_norm(s, .24), sr)

    # --- creak / doors ---
    length = int(2.2 * sr)
    tt = np.arange(length) / sr
    freq = 60 + 17 * np.sin(2 * np.pi * .23 * tt) + np.random.randn(length).cumsum() * .008
    creak = np.sin(2 * np.pi * freq * tt) * env_adsr(length, .2, .2, .5, .6, sr) * .12
    grit = lowpass_noise(length, .03) * .05 * env_adsr(length, .2, .2, .4, .7, sr)
    write_wav("door_open.wav", rms_norm(creak + grit, .35), sr)

    length = int(.7 * sr)
    tt = np.arange(length) / sr
    thump = np.sin(2 * np.pi * 55 * tt) * np.exp(-tt * 16)
    rattle = lowpass_noise(length, .25) * np.exp(-tt * 30) * .15
    write_wav("door_close.wav", rms_norm(thump * .65 + rattle, .48), sr)
    write_wav("door_slam.wav", rms_norm(np.vstack([thump, thump]).reshape(-1) * .9 + np.random.randn(length * 2) * .02, .55), sr)

    length = int(.5 * sr)
    tt = np.arange(length) / sr
    rat = lowpass_noise(length, .3) * np.exp(-tt * 12) + .1 * np.sin(2 * np.pi * 120 * tt) * np.exp(-tt * 18)
    write_wav("door_locked.wav", rms_norm(rat, .34), sr)

    # --- keypad / interaction ---
    for name, freq, length_s, amp in [
        ("keypad_beep.wav", 680, .09, .22),
        ("keypad_error.wav", 170, .45, .25),
        ("keypad_ok.wav", 880, .22, .22),
        ("ui_hover.wav", 360, .035, .10),
        ("ui_click.wav", 230, .07, .16),
        ("interact.wav", 520, .08, .12),
        ("pickup.wav", 1040, .5, .15),
        ("unlock.wav", 480, .45, .22),
        ("page.wav", 1600, .22, .08),
    ]:
        length = int(length_s * sr)
        tt = np.arange(length) / sr
        e = env_adsr(length, .005, .04, .35, length_s * .7, sr)
        if name == "pickup.wav":
            s = (np.sin(2 * np.pi * 880 * tt) * .6 + np.sin(2 * np.pi * 1320 * tt) * .25) * e
        elif name == "keypad_error.wav":
            s = (np.sin(2 * np.pi * 155 * tt) + .4 * np.sin(2 * np.pi * 157 * tt)) * e
        elif name == "unlock.wav":
            s = (lowpass_noise(length, .12) * np.exp(-tt * 18) * .35
                 + np.sin(2 * np.pi * 85 * tt) * np.exp(-tt * 12) * .3)
            s += np.sin(2 * np.pi * 440 * tt) * env_adsr(length, .01, .05, .0, .3, sr) * .1
        elif name == "page.wav":
            s = lowpass_noise(length, .35) * e * (.4 + .6 * np.random.rand(length))
        else:
            s = np.sin(2 * np.pi * freq * tt) * e
            if name == "ui_hover.wav":
                s *= .5
        write_wav(name, rms_norm(s, amp), sr)

    # --- fluorescent buzz (sparse use) ---
    length = int(3.5 * sr)
    tt = np.arange(length) / sr
    buzz = (np.sign(np.sin(2 * np.pi * 120 * tt)) * .012
            + .02 * np.sin(2 * np.pi * 240 * tt) * (0.6 + .4 * np.sin(2 * np.pi * 1.3 * tt)))
    buzz *= env_adsr(length, .15, .3, .6, .7, sr)
    write_wav("light_buzz.wav", rms_norm(buzz, .2), sr)

    # --- elevator ---
    length = int(7.0 * sr)
    tt = np.arange(length) / sr
    hum = (.055 * np.sin(2 * np.pi * 44 * tt) + .03 * np.sin(2 * np.pi * 58 * tt)
           + .013 * np.sin(2 * np.pi * 118 * tt)) * (0.7 + .3 * np.sin(2 * np.pi * .4 * tt))
    hum *= env_adsr(length, .2, .4, .8, .8, sr)
    ding = np.zeros(length)
    pos = int(5.0 * sr)
    dl = int(.7 * sr)
    td = np.arange(dl) / sr
    ding[pos:pos + dl] = (np.sin(2 * np.pi * 880 * td) + .3 * np.sin(2 * np.pi * 1760 * td)) * np.exp(-td * 5) * .12
    write_wav("elevator.wav", rms_norm(hum + ding, .35), sr)

    # --- glitch / transition / ending stings ---
    length = int(1.3 * sr)
    tt = np.arange(length) / sr
    g = np.random.randn(length) * 0.12
    g = np.round(g * 22) / 22
    g *= (0.3 + .7 * (np.sin(2 * np.pi * 15 * tt) > .2))
    g += .06 * np.sin(2 * np.pi * (100 + 900 * np.sin(2 * np.pi * 7 * tt)) * tt)
    g *= env_adsr(length, .002, .05, .4, .7, sr)
    write_wav("glitch.wav", rms_norm(g, .45), sr)

    length = int(3.4 * sr)
    tt = np.arange(length) / sr
    tr = lowpass_noise(length, .003) * 2.0
    tr += .02 * np.sin(2 * np.pi * (70 + 25 * tt) * tt)
    tr *= env_adsr(length, 1.0, .5, .4, 1.2, sr)
    write_wav("transition.wav", rms_norm(tr, .30), sr)

    length = int(3.0 * sr)
    tt = np.arange(length) / sr
    tone = (.06 * np.sin(2 * np.pi * 55 * tt) + .035 * np.sin(2 * np.pi * 82.5 * tt)
            + .018 * np.sin(2 * np.pi * 110 * tt))
    tone *= env_adsr(length, .15, .8, .4, 1.2, sr)
    write_wav("ending_tone.wav", rms_norm(tone, .33), sr)

    length = int(2.2 * sr)
    tt = np.arange(length) / sr
    heart = np.zeros(length)
    for pos in [0.0, 0.32, 1.1, 1.42]:
        i = int(pos * sr)
        tl = np.arange(int(.18 * sr)) / sr
        if i + len(tl) <= length:
            heart[i:i + len(tl)] += np.sin(2 * np.pi * 48 * tl) * np.exp(-tl * 22) * .7
    heart *= env_adsr(length, .01, .2, .6, .7, sr)
    write_wav("heartbeat.wav", rms_norm(heart, .38), sr)

    length = int(1.8 * sr)
    tt = np.arange(length) / sr
    glitch2 = np.zeros(length)
    for _ in range(8):
        pos = int(random.uniform(0, 1.2) * sr)
        seg = int(random.uniform(.03, .16) * sr)
        if pos + seg < length:
            freq = random.choice([140, 220, 330, 660])
            glitch2[pos:pos + seg] = np.sign(np.sin(2 * np.pi * freq * tt[:seg])) * .08
    glitch2 *= env_adsr(length, .01, .2, .4, .4, sr)
    write_wav("signal_lost.wav", rms_norm(glitch2 + .02 * np.random.randn(length), .36), sr)

    # --- distant intercom / whisper texture ---
    length = int(4.5 * sr)
    tt = np.arange(length) / sr
    w = np.sin(2 * np.pi * 310 * tt + 0.8 * np.sin(2 * np.pi * 2.3 * tt)) * .03
    w += np.sin(2 * np.pi * 465 * tt) * .012
    w *= (0.35 + .65 * (np.sin(2 * np.pi * .8 * tt) > 0))
    w *= env_adsr(length, .5, .5, .6, 1.0, sr)
    write_wav("intercom.wav", rms_norm(w, .24), sr)

    # --- gentle ending reprise (short) ---
    length = int(10.0 * sr)
    tt = np.arange(length) / sr
    pad = (.018 * np.sin(2 * np.pi * 196 * tt) + .012 * np.sin(2 * np.pi * 246.94 * tt)
           + .008 * np.sin(2 * np.pi * 392 * tt))
    pad *= env_adsr(length, 1.0, 1.0, .6, 2.0, sr)
    write_wav("last_light.wav", rms_norm(pad, .22), sr)

    dur = 30.0
    n = int(dur * sr)
    tt = np.arange(n) / sr
    throb = (0.5 + 0.5 * np.sin(2 * np.pi * tt / 1.85 - np.pi / 2)) ** 6
    sub = .055 * np.sin(2 * np.pi * 36.71 * tt) * (.42 + .58 * throb)
    cluster = np.zeros(n)
    for f, phase in [(73.42, 0.0), (77.78, .8), (103.83, 1.7), (110.0, 2.4)]:
        cluster += (np.sin(2 * np.pi * f * tt + .35 * np.sin(2 * np.pi * .07 * tt + phase))
                    + .28 * np.sin(2 * np.pi * f * 2.01 * tt + phase))
    cluster *= .013 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 7.3 + 1.1))
    high = np.zeros(n)
    for f, phase in [(587.33, .3), (622.25, 1.1), (880.0, 2.0), (932.33, 2.8)]:
        gate = 0.18 + 0.82 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 6.3 + phase)) ** 3
        high += (np.sin(2 * np.pi * f * tt + .6 * np.sin(2 * np.pi * .4 * tt + phase))
                 + .30 * np.sin(2 * np.pi * f * 2.02 * tt)) * gate
    high *= .0075
    heart = np.zeros(n)
    for pos in np.arange(0.6, dur, 1.8):
        add_tone(heart, pos, .65, 46.0, .080, 18.0,
                 [(1.0, 1.0, 0.0), (2.0, .35, .5)])
        add_tone(heart, pos + .23, .55, 42.0, .050, 20.0,
                 [(1.0, 1.0, 0.0), (1.99, .25, .4)])
    impacts = np.zeros(n)
    for pos in [0.25, 6.9, 13.6, 21.4, 26.8]:
        add_tone(impacts, pos, 3.0, 54.0, .050, 2.6,
                 [(1.0, 1.0, 0.0), (2.02, .45, .6), (2.71, .22, 1.2)])
    whisper = lowpass_noise(n, 0.060) * 0.36
    whisper *= .08 + .92 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 4.7 + 1.2)) ** 8
    screech = np.zeros(n)
    for pos in [4.6, 13.7, 22.6]:
        i = int(pos * sr)
        length = min(int(2.0 * sr), n - i)
        ts = np.arange(length) / sr
        freq = 780 + 260 * ts + 90 * np.sin(2 * np.pi * 7 * ts)
        s = (np.sin(2 * np.pi * freq * ts) + .30 * np.sin(2 * np.pi * freq * 2.01 * ts))
        s *= np.exp(-ts * 1.6) * env_adsr(length, .06, .25, .35, 1.2, sr) * .019
        screech[i:i + length] += s
    amb = sub + cluster + high + heart + impacts + whisper + screech
    amb = loopify(amb, 1.2)
    write_wav("loss_theme.wav", rms_norm(amb, .52), sr)


def main() -> None:
    print("Painting textures...")
    make_floor_checker().save(TEX / "floor_checker.png")
    make_concrete("concrete.png", (72, 73, 68), 23).save(TEX / "concrete.png")
    make_wall_plaster().save(TEX / "wall_plaster.png")
    make_wall_tile().save(TEX / "wall_tile.png")
    make_wood().save(TEX / "wood.png")
    make_metal().save(TEX / "metal.png")
    make_grass().save(TEX / "grass.png")
    make_ghost().save(TEX / "ghost.png")
    make_logo().save(TEX / "title_logo.png")
    make_scrawl("IT ALWAYS\nCOMES BACK", "scrawl_back.png")
    make_scrawl("YOU ARE\nSUBJECT 06", "scrawl_subject.png", (142, 40, 33, 195), (768, 300))
    make_scrawl("41", "scrawl_41.png", (163, 159, 139, 140), (420, 160))
    print("Synthesizing audio...")
    make_audio()
    print("Assets written to", ROOT)


if __name__ == "__main__":
    main()
