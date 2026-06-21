#!/usr/bin/env python3
"""Erstellt das DMG-Hintergrundbild (560x360px) ohne externe Abhängigkeiten."""
import struct, zlib, sys, math

W, H = 560, 380

def png_chunk(tag, data):
    c = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", c)

def make_png(pixels):
    rows = []
    for y in range(H):
        row = b"\x00"
        for x in range(W):
            r, g, b = pixels[y][x]
            row += bytes([r, g, b])
        rows.append(row)
    raw = zlib.compress(b"".join(rows), 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", raw)
        + png_chunk(b"IEND", b"")
    )

def lerp(a, b, t):
    return int(a + (b - a) * t)

# Hintergrund: dunkles Blaugrau-Verlauf von oben nach unten
BG_TOP    = (22, 26, 34)
BG_BOTTOM = (14, 17, 22)

# Pfeil-Farbe (DJ-orange)
ARROW = (220, 120, 40)
TEXT_BRIGHT = (200, 205, 215)
TEXT_DIM    = (110, 115, 125)

pixels = []
for y in range(H):
    t = y / (H - 1)
    r = lerp(BG_TOP[0], BG_BOTTOM[0], t)
    g = lerp(BG_TOP[1], BG_BOTTOM[1], t)
    b = lerp(BG_TOP[2], BG_BOTTOM[2], t)
    pixels.append([(r, g, b)] * W)

def draw_rect(x0, y0, x1, y1, color, alpha=1.0):
    for y in range(max(0,y0), min(H,y1)):
        for x in range(max(0,x0), min(W,x1)):
            br, bg, bb = pixels[y][x]
            cr, cg, cb = color
            pixels[y][x] = (
                lerp(br, cr, alpha),
                lerp(bg, cg, alpha),
                lerp(bb, cb, alpha),
            )

def draw_arrow(cx, y, size, color):
    """Pfeil nach rechts."""
    shaft_w = size * 2
    shaft_h = size // 3
    head_w  = size
    head_h  = size * 2 // 3
    # Schaft
    draw_rect(cx - shaft_w, y - shaft_h // 2,
              cx,            y + shaft_h // 2 + 1, color)
    # Spitze (Dreieck als gefüllte Rechtecke gestapelt)
    for i in range(head_h):
        t = i / head_h
        half = int(head_h * (1 - t))
        draw_rect(cx + i, y - half, cx + i + 1, y + half + 1, color)

def draw_circle(cx, cy, r, color, alpha=1.0):
    for y in range(max(0, cy-r), min(H, cy+r+1)):
        for x in range(max(0, cx-r), min(W, cx+r+1)):
            if (x-cx)**2 + (y-cy)**2 <= r**2:
                br, bg, bb = pixels[y][x]
                cr, cg, cb = color
                pixels[y][x] = (lerp(br,cr,alpha), lerp(bg,cg,alpha), lerp(bb,cb,alpha))

# ── Subtile Glanzlinie oben ────────────────────────────────────────────────────
draw_rect(0, 0, W, 1, (60, 65, 80), 0.4)

# ── App links ────────────────────────────────────────────────────────────────
draw_circle(150, 200, 52, (35, 40, 52), 0.5)

# ── Pfeil Mitte ──────────────────────────────────────────────────────────────
draw_arrow(300, 200, 14, ARROW)

# ── Applications rechts ──────────────────────────────────────────────────────
draw_circle(410, 200, 52, (35, 40, 52), 0.5)

# Ausgabe
out = sys.argv[1] if len(sys.argv) > 1 else "dmg_bg.png"
with open(out, "wb") as f:
    f.write(make_png(pixels))
print(f"Background: {out}")
