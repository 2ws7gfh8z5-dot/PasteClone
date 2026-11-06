#!/usr/bin/env python3
"""Generate every Just Paste icon from geometry — no source image, no metadata.

Design: flat rounded-square tile, deep ink background, a single terracotta
"paste" mark made of two offset rounded rectangles (the clipboard sheet and the
sheet behind it) with a notch. Deliberately geometric: no gradients, no glow,
no texture. Only flat fills, so it stays crisp at 16 px.

Run: python3 scripts/make_icons.py
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONSET = os.path.join(ROOT, "PasteClone/Resources/Assets.xcassets/AppIcon.appiconset")
ASSETS = os.path.join(ROOT, "PasteClone/Resources/Assets.xcassets")

# Palette, pulled from Theme.swift so the icon matches the app.
INK = (26, 23, 20, 255)          # bgDark
PAPER = (250, 245, 235, 255)     # bgLight
CLAY = (204, 105, 51, 255)       # accent
CLAY_DIM = (120, 62, 35, 255)    # accentSoftDark


def draw_mark(size, bg, fg, accent):
    """Draw the mark on a transparent canvas of `size`, mark occupying ~62%."""
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Rounded tile. Corner radius follows Apple's squircle-ish proportion.
    pad = round(s * 0.055)
    r = round(s * 0.225)
    d.rounded_rectangle([pad, pad, s - pad, s - pad], radius=r, fill=bg)

    # Mark box.
    m = s * 0.62
    x0 = (s - m) / 2
    y0 = (s - m) / 2

    # Back sheet: offset up-right, only its outline edge shows.
    bw = m * 0.72
    bh = m * 0.80
    bx = x0 + m * 0.26
    by = y0
    d.rounded_rectangle(
        [bx, by, bx + bw, by + bh],
        radius=m * 0.10,
        fill=accent if accent else fg,
    )

    # Front sheet: the actual clipboard, drawn over the back one.
    fw = m * 0.74
    fh = m * 0.82
    fx = x0
    fy = y0 + m * 0.16
    d.rounded_rectangle(
        [fx, fy, fx + fw, fy + fh],
        radius=m * 0.10,
        fill=bg,
        outline=fg,
        width=max(1, round(m * 0.075)),
    )

    # Two text rules inside the front sheet.
    lx0 = fx + fw * 0.20
    lx1 = fx + fw * 0.80
    lh = max(1, round(m * 0.072))
    for i, frac in enumerate((0.34, 0.56)):
        ly = fy + fh * frac
        d.rounded_rectangle(
            [lx0, ly, lx1 if i == 0 else lx1 - fw * 0.28, ly + lh],
            radius=lh / 2,
            fill=accent if i == 0 else fg,
        )
    return img


def draw_mono(size):
    """Template menu-bar glyph: solid silhouette with punched-out rules.

    Draws at 4x then downsamples so the 1-2 px strokes survive at 18-22 px.
    """
    s = size
    big = s * 4
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = big * 0.80
    x0 = (big - m) / 2
    y0 = (big - m) / 2
    # Back sheet
    bw, bh = m * 0.58, m * 0.70
    d.rounded_rectangle([x0 + m * 0.32, y0, x0 + m * 0.32 + bw, y0 + bh],
                        radius=m * 0.13, fill=(0, 0, 0, 255))
    # Front sheet
    fw, fh = m * 0.62, m * 0.72
    fx, fy = x0, y0 + m * 0.24
    d.rounded_rectangle([fx, fy, fx + fw, fy + fh], radius=m * 0.13, fill=(0, 0, 0, 255))
    # Punch two rules out of the front sheet so it reads as text at small sizes.
    lx0 = fx + fw * 0.20
    lx1 = fx + fw * 0.80
    lh = m * 0.085
    for i, frac in enumerate((0.30, 0.56)):
        ly = fy + fh * frac
        d.rounded_rectangle([lx0, ly, lx1 if i == 0 else lx1 - fw * 0.30, ly + lh],
                            radius=lh / 2, fill=(0, 0, 0, 0))
    return img.resize((s, s), Image.LANCZOS)


def save(img, path):
    img.save(path, "PNG", optimize=True)


def main():
    # AppIcon: light + dark appearances, every size Xcode references.
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save(draw_mark(size, INK, PAPER, CLAY), os.path.join(ICONSET, f"icon_{size}.png"))
        save(draw_mark(size, PAPER, INK, CLAY), os.path.join(ICONSET, f"dark_{size}.png"))

    # Standalone imagesets used by the app / website / Rust client.
    save(draw_mark(512, INK, PAPER, CLAY), os.path.join(ASSETS, "icon_light.imageset/icon_light.png"))
    save(draw_mark(512, PAPER, INK, CLAY), os.path.join(ASSETS, "icon_dark.imageset/icon_dark.png"))
    save(draw_mono(64), os.path.join(ASSETS, "icon_mono.imageset/icon_mono.png"))
    save(draw_mono(36), os.path.join(ASSETS, "MenuBarIcon.imageset/MenuBarIcon.png"))

    save(draw_mark(1024, INK, PAPER, CLAY),
         os.path.join(ROOT, "CrossPlatformClient/assets/just-paste-icon.png"))
    web = os.path.join(ROOT, "website/assets/just-paste-icon.png")
    if os.path.isdir(os.path.dirname(web)):
        save(draw_mark(1024, INK, PAPER, CLAY), web)

    # The GPT-sourced design originals are gone; the geometry above is the source.
    for stale in ("just-paste-app-icon-source.png", "just-paste-app-icon-dark-source.png",
                  "just-paste-menubar-source.png"):
        p = os.path.join(ROOT, "design", stale)
        if os.path.exists(p):
            os.remove(p)
            print("removed", os.path.relpath(p, ROOT))


if __name__ == "__main__":
    main()
    print("icons written")
