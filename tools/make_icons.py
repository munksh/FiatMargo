#!/usr/bin/env python3
"""
Generate fiat margo's launcher icons.

    python3 tools/make_icons.py

Writes icons/{86x86,108x108,128x128,172x172}/harbour-fiatmargo.png

THE HOUSE ICON LANGUAGE
-----------------------
Launcher icons do not follow the ambience.

The Sailfish silhouette is NOT a rounded square. It is a square in which the
inscribed circle replaces two DIAGONALLY OPPOSITE corners: top-left and
bottom-right are arcs of radius side/2, while top-right and bottom-left stay
perfectly square. Drawn as a union, never a subtraction:

    shape = inscribed circle  U  top-right quadrant  U  bottom-left quadrant

And the symbol repeats the shape:

    - the ground IS the shape, in dark warm #1E1A12
    - a cream #F4EED8 field repeats the SAME silhouette, centred, at 60.5%
    - the instrument is drawn ON the cream, in the ground colour
    - one small accent stroke, in the app's own colour
    - no text

Everything must sit inside the inscribed circle -- radius 0.302 of the side
from the centre -- because the two arcs cut away exactly the corners a
horizontal composition would run into.

MARGO'S MARK
------------
A photograph, and the screen edges that would have cut it.

The dark portrait rectangle is the photo. The two accent rules stand OUTSIDE
it, where the phone's screen edges fall -- which is the whole point of the
app: the photo sits safely inside the strip, and the crop lands on the cream.
"""

from pathlib import Path
from PIL import Image, ImageDraw

GROUND = (0x1E, 0x1A, 0x12, 255)
CREAM = (0xF4, 0xEE, 0xD8, 255)
ACCENT = (0x1F, 0x6E, 0x7B, 255)   # deep sea

SIZES = [86, 108, 128, 172]
SS = 8  # supersample factor; the arcs need it

INNER_FIELD = 0.605      # cream silhouette, as a fraction of the side
SAFE_RADIUS = 0.302      # nothing may sit further than this from the centre

# the photo, as fractions of the side (half-extents from centre)
PHOTO_HW = 0.100
PHOTO_HH = 0.175

# the screen edges that would have cut it
RULE_X = 0.185
RULE_HH = 0.190
RULE_W = 0.028


def silhouette_mask(side: int) -> Image.Image:
    """The Sailfish shape as an L-mode mask: circle U top-right U bottom-left."""
    mask = Image.new("L", (side, side), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([0, 0, side - 1, side - 1], fill=255)
    d.rectangle([side / 2, 0, side - 1, side / 2], fill=255)          # top-right
    d.rectangle([0, side / 2, side / 2, side - 1], fill=255)          # bottom-left
    return mask


def check_inside_safe_circle(side: int) -> None:
    """Fail loudly rather than shipping a mark the arcs would clip."""
    limit = SAFE_RADIUS
    corners = {
        "photo corner": (PHOTO_HW ** 2 + PHOTO_HH ** 2) ** 0.5,
        "rule corner": (((RULE_X + RULE_W / 2) ** 2) + RULE_HH ** 2) ** 0.5,
    }
    for name, dist in corners.items():
        if dist > limit:
            raise SystemExit(
                f"{name} sits {dist:.3f} from the centre, outside the safe "
                f"radius {limit:.3f} -- the silhouette's arcs would clip it."
            )


def build(side: int) -> Image.Image:
    s = side * SS
    icon = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    # ---- the ground is the shape ----
    ground = Image.new("RGBA", (s, s), GROUND)
    icon.paste(ground, (0, 0), silhouette_mask(s))

    # ---- the cream field repeats the shape ----
    inner = int(round(s * INNER_FIELD))
    off = (s - inner) // 2
    field = Image.new("RGBA", (inner, inner), CREAM)
    icon.paste(field, (off, off), silhouette_mask(inner))

    # ---- the mark, drawn on the cream ----
    d = ImageDraw.Draw(icon)
    c = s / 2

    # the two screen edges, in the accent, standing outside the photo
    for sign in (-1, 1):
        x = c + sign * RULE_X * s
        d.rectangle(
            [x - RULE_W * s / 2, c - RULE_HH * s,
             x + RULE_W * s / 2, c + RULE_HH * s],
            fill=ACCENT,
        )

    # the photograph itself, in the ground colour
    d.rectangle(
        [c - PHOTO_HW * s, c - PHOTO_HH * s,
         c + PHOTO_HW * s, c + PHOTO_HH * s],
        fill=GROUND,
    )

    return icon.resize((side, side), Image.LANCZOS)


def main() -> None:
    check_inside_safe_circle(172)
    root = Path(__file__).resolve().parent.parent
    for side in SIZES:
        out_dir = root / "icons" / f"{side}x{side}"
        out_dir.mkdir(parents=True, exist_ok=True)
        target = out_dir / "harbour-fiatmargo.png"
        build(side).save(target)
        print(f"wrote {target.relative_to(root)}")


if __name__ == "__main__":
    main()
