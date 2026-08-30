#!/usr/bin/env python3
"""
Generate the 1080x540 store cover image for the Harbour listing.

    python3 tools/make_cover.py

Writes store/cover-1080x540.png

WHY THIS IS NOT A SCREENSHOT COLLAGE
------------------------------------
Harbour takes screenshots separately, and a cover made of shrunken screenshots
reads as noise at listing size. The cover's job is to say the app's name and
what it is, in the family's own paper and type, and to be recognisable beside
the other fiat apps.

So: the launcher icon at full size on the fiat paper, the wordmark, one line
that states the problem, and the maker's name small in the corner. The same
five constants that draw the icon draw the little diagram on the right, so the
cover cannot drift away from the icon.

The serif here is DejaVu Serif Italic rather than Georgia -- Georgia is what
the app uses on the device, but it is not redistributable and is not installed
on most build machines. At cover size the difference is a slightly wider
letterform and nothing else.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

from make_icons import build as build_icon, ACCENT

W, H = 1080, 540

PAPER_HIGH = (0xF2, 0xEF, 0xE8)
PAPER_LOW = (0xD8, 0xD2, 0xC6)
PRIMARY = (0x1A, 0x1A, 0x1A)
SECONDARY = (0x6B, 0x6B, 0x66)

SERIF_I = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Italic.ttf"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def paper(w: int, h: int) -> Image.Image:
    """The family's vertical gradient, top to bottom."""
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line(
            [(0, y), (w, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(PAPER_HIGH, PAPER_LOW)),
        )
    return img


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    img = paper(W, H)
    d = ImageDraw.Draw(img)

    # ---- the icon, straight from the launcher generator ----
    icon = build_icon(256).resize((300, 300), Image.LANCZOS)
    img.paste(icon, (78, (H - 300) // 2), icon)

    x = 452
    wordmark = ImageFont.truetype(SERIF_I, 92)
    tagline = ImageFont.truetype(SERIF, 27)
    small = ImageFont.truetype(SANS, 20)
    tiny = ImageFont.truetype(SERIF_I, 21)

    d.text((x, 158), "fiat margo", font=wordmark, fill=PRIMARY)

    d.rectangle([x, 274, x + 96, 276], fill=ACCENT[:3])

    d.text((x, 306), "Sailfish crops a photo twice on its", font=tagline, fill=PRIMARY)
    d.text((x, 344), "way to becoming an ambience.", font=tagline, fill=PRIMARY)
    d.text((x, 392), "margo pads it out first, so the crop", font=small, fill=SECONDARY)
    d.text((x, 419), "lands on fill instead of on your picture.", font=small, fill=SECONDARY)

    # Fail loudly rather than shipping a cover with a clipped word. The first
    # draft put a diagram on the right and the wordmark ran straight under it;
    # nothing warned, it just looked broken.
    limit = W - 78
    for label, txt, font in (("wordmark", "fiat margo", wordmark),
                             ("tagline", "Sailfish crops a photo twice on its", tagline),
                             ("sub", "lands on fill instead of on your picture.", small)):
        right = x + d.textlength(txt, font=font)
        if right > limit:
            raise SystemExit(f"{label} reaches {right:.0f}px, past the {limit}px margin")

    mark = "munkstolen"
    d.text((W - 78 - d.textlength(mark, font=tiny), H - 62), mark, font=tiny, fill=SECONDARY)

    out_dir = root / "store"
    out_dir.mkdir(exist_ok=True)
    target = out_dir / "cover-1080x540.png"
    img.save(target)
    print(f"wrote {target.relative_to(root)}  ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
