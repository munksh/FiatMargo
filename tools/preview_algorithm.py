#!/usr/bin/env python3
"""
A line-for-line port of AmbienceComposer::compose() into Python.

This exists so the maths can be checked, and the two fill modes compared,
without a build-deploy cycle onto the phone. If you change the C++, change
this too and re-run it -- it is the cheapest way to see what an edit does.

    python3 tools/preview_algorithm.py photo.jpg out.png

With no arguments it renders a synthetic test photo instead, which is enough
to check the geometry.
"""

import sys
from PIL import Image, ImageDraw, ImageFilter

EDGE_COLOUR = 0
EDGE_SMEAR = 1


def compose(src: Image.Image, size: int, aspect: float, fill_mode: int,
            zoom: float = 0.0, offset_x: float = 0.0, offset_y: float = 0.0) -> Image.Image:
    """Identical to AmbienceComposer::compose()."""
    src = src.convert("RGB")

    strip_w = size * aspect
    strip_h = size

    # zoom 0 -> whole photo fits inside the visible strip, nothing lost
    # zoom 1 -> photo fills the strip completely, edges cropped
    contain = min(strip_w / src.width, strip_h / src.height)
    cover = max(strip_w / src.width, strip_h / src.height)
    scale = contain + (cover - contain) * zoom

    pw = max(1, round(src.width * scale))
    ph = max(1, round(src.height * scale))
    px = round(size / 2 - pw / 2 + offset_x * size)
    py = round(size / 2 - ph / 2 + offset_y * size)

    placed = src.resize((pw, ph), Image.LANCZOS)

    # ---- background: built small, blurred there, then scaled up ----
    bg_size = max(128, min(size // 4, 512))
    k = bg_size / size
    spw = max(1, round(pw * k))
    sph = max(1, round(ph * k))
    spx = round(px * k)
    spy = round(py * k)

    small_placed = placed.resize((spw, sph), Image.LANCZOS)

    # Edge-replicate: every pixel outside the photo takes the nearest pixel
    # inside it. This is the step that makes the fill "a colour present in the
    # edges" rather than an invented one.
    background = Image.new("RGB", (bg_size, bg_size))
    sp = small_placed.load()
    bp = background.load()
    for y in range(bg_size):
        sy = min(max(y - spy, 0), sph - 1)
        for x in range(bg_size):
            sx = min(max(x - spx, 0), spw - 1)
            bp[x, y] = sp[sx, sy]

    # The two modes are the SAME construction with different blur radii.
    radius = max(1, bg_size // 5) if fill_mode == EDGE_COLOUR else max(1, bg_size // 28)
    # Three box passes approximate the C++ side's separable box blur.
    for _ in range(3):
        background = background.filter(ImageFilter.BoxBlur(radius))

    out = background.resize((size, size), Image.LANCZOS)
    out.paste(placed, (px, py))
    return out


def strip_view(square: Image.Image, aspect: float) -> Image.Image:
    """What the phone actually shows: the centred vertical strip, full height."""
    size = square.width
    w = round(size * aspect)
    left = (size - w) // 2
    return square.crop((left, 0, left + w, size))


def synthetic_photo(w=3000, h=4000) -> Image.Image:
    """A portrait with an obvious off-centre subject and distinct edges."""
    img = Image.new("RGB", (w, h), (206, 186, 152))
    d = ImageDraw.Draw(img)
    for i in range(h):                       # sky-to-ground gradient
        t = i / h
        d.line([(0, i), (w, i)],
               fill=(int(150 + 80 * t), int(170 + 40 * t), int(190 - 40 * t)))
    d.ellipse([w * 0.34, h * 0.30, w * 0.66, h * 0.56], fill=(247, 214, 178))  # face
    d.rectangle([w * 0.30, h * 0.56, w * 0.70, h], fill=(70, 92, 110))         # body
    d.rectangle([0, 0, w, h * 0.04], fill=(40, 60, 80))                        # top band
    d.rectangle([0, h * 0.96, w, h], fill=(60, 50, 40))                        # bottom band
    return img


def main() -> None:
    if len(sys.argv) > 1:
        src = Image.open(sys.argv[1])
        try:
            from PIL import ImageOps
            src = ImageOps.exif_transpose(src)
        except Exception:
            pass
    else:
        src = synthetic_photo()

    out_path = sys.argv[2] if len(sys.argv) > 2 else "margo_comparison.png"

    size = 1024
    aspect = 0.45

    # Row 1: the two fill modes, as the square Gallery will show you.
    # Row 2: what the phone actually displays, at three zoom levels -- which is
    #        the control that decides how much fill you end up looking at.
    sq = 460
    strip_h = 460
    strip_w = round(strip_h * aspect)
    pad = 24
    top = 40

    row2_y = top + sq + 70
    width = pad * 2 + max(sq * 2 + pad, (strip_w + pad) * 3)
    sheet = Image.new("RGB", (width, row2_y + strip_h + 50), (242, 239, 232))
    d = ImageDraw.Draw(sheet)

    for i, (mode, name) in enumerate([(EDGE_COLOUR, "Edge colour"),
                                      (EDGE_SMEAR, "Edge smear")]):
        square = compose(src, size, aspect, mode)
        x = pad + i * (sq + pad)
        sheet.paste(square.resize((sq, sq), Image.LANCZOS), (x, top))
        d.text((x, top - 16), name + "  (the square Gallery sees)", fill=(26, 26, 26))

    for i, zoom in enumerate([0.0, 0.45, 1.0]):
        square = compose(src, size, aspect, EDGE_SMEAR, zoom=zoom)
        strip = strip_view(square, aspect).resize((strip_w, strip_h), Image.LANCZOS)
        x = pad + i * (strip_w + pad)
        sheet.paste(strip, (x, row2_y))
        label = {0.0: "zoom 0 - whole photo",
                 0.45: "zoom 45%",
                 1.0: "zoom 100% - fills"}[zoom]
        d.text((x, row2_y - 16), label, fill=(26, 26, 26))

    d.text((pad, row2_y + strip_h + 16),
           "Row 2 is on-screen, edge smear. Note how much fill you look at at zoom 0.",
           fill=(120, 120, 120))

    sheet.save(out_path)
    print(f"wrote {out_path}")

    # ---- geometry check ----
    strip_w = size * aspect
    contain = min(strip_w / src.width, size / src.height)
    pw, ph = src.width * contain, src.height * contain
    left, right = size / 2 - pw / 2, size / 2 + pw / 2
    s_left, s_right = size / 2 - strip_w / 2, size / 2 + strip_w / 2
    inside = left >= s_left - 0.5 and right <= s_right + 0.5 and ph <= size + 0.5
    print(f"photo {pw:.1f}x{ph:.1f} inside strip [{s_left:.1f},{s_right:.1f}] "
          f"of a {size} square -> {'OK' if inside else 'FAILS'}")


if __name__ == "__main__":
    main()
