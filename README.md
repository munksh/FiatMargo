# fiat margo

*margo, marginis* — the edge, the border, the margin of a page.

A Sailfish OS app that prepares a photo for use as an ambience, so that the
picture you framed is the picture you end up looking at.

Part of the fiat family: **lux** measures light, **vox** finds pitch, **mos**
keeps habits, **agenda** keeps promises, **margo** keeps edges.

---

## The problem

Sailfish crops a photo **twice** on its way to becoming an ambience:

1. the photo is forced into a **square**
2. that square is stretched to the height of the screen and the **left and
   right edges are sliced off** to match the screen's width

Neither step is WYSIWYG — the official documentation says so outright. A
normally framed portrait therefore loses its edges twice, and what survives is
a sliver of whatever happened to be dead centre.

## The fix

margo does the opposite. It places the whole, uncropped photo inside the strip
that survives *both* crops, and fills everything around it with colour taken
from the photo's own edges. The crop still happens — it just lands on fill
instead of on your picture.

### The part people miss

The surviving strip is **full height**. So the fill above and below the photo
is *not* discarded — it is the part you look at every time you glance at your
phone. Only the left and right fill is thrown away. That is the entire reason
the fill is sampled from the image rather than set to black.

## What it cannot do

It cannot create the ambience for you. There is no `Ambience` permission on
the [Harbour allowlist](https://docs.sailfishos.org/Develop/Apps/Harbour/Allowed_Permissions/),
so no Store app may set one. margo writes a prepared image to
`Pictures/Ambiences` and you finish in Gallery, where the ambience button now
has nothing left to ruin.

---

## The two fills

Both are the same construction — extend the photo's edge pixels outward — with
different blur radii. That is the whole difference, and it is one number.

| Mode | Radius | Looks like |
|---|---|---|
| **Edge colour** | `bgSize / 5` | soft fields of the colours found along each edge |
| **Edge smear** | `bgSize / 28` | each edge continues outward, row by row |

Edge smear wins whenever the photo has a horizon, a wall or any strong
horizontal structure, because the line simply carries on. Edge colour wins when
the edges are busy and a continuation would look like a mistake.

## Controls

- **Zoom** — 0 shows the whole photo (and a lot of fill); 1 fills the screen
  completely (and crops). Around 45% is usually the sweet spot.
- **Drag** the preview to move the photo.
- **Centre** — puts the photo back in the middle after a drag.
- **Square / On screen** — switch between what Gallery shows you and what the
  phone will actually display.

Two things are deliberately NOT choices, because both asked the user a question
they had no way to answer. Each is one constant at the top of
`src/ambiencecomposer.cpp`:

| Constant | Value | Why |
|---|---|---|
| `kOutputSize` | 2048 | what Sailfish's own built-in ambiences are |
| `kSafety` | 0.04 | margo treats the surviving strip as 4% narrower than measurement says it is, so the photo lands just inside the safe area rather than exactly on its edge — on the real screen you get slightly more photo than the preview promised, never less |

---

## Building

```bash
~/SailfishOS/bin/sfdk -c target=SailfishOS-5.0.0.62-i486 build
~/SailfishOS/bin/sfdk deploy --sdk
```

Or from Qt Creator: start the **VirtualBox** build engine (never Docker — it
cannot reach the emulator), pick the `-i486` kit for the emulator, green
triangle.

**Any change to the `.pro`, or any new source file: Build → Clean All → Run
qmake → Build.**

### Testing it

The emulator is fine for layout, both fiat colour modes and navigation. It has
no camera, but margo never needs one — it reads photos from the gallery, so you
can drop a few JPEGs into the emulator's Pictures folder and work entirely
there.

**Deploy from Qt Creator, then launch from the icon.** Qt Creator's Run button
starts the binary directly and never reads the desktop file, so sailjail — and
therefore the `Pictures` permission — is not applied that way.

To watch it:

```bash
devel-su journalctl -af | grep -i margo
```

## Tools

```bash
python3 tools/make_icons.py          # regenerate the launcher icons
python3 tools/preview_algorithm.py   # render a fill/zoom comparison sheet
python3 tools/preview_algorithm.py photo.jpg out.png
```

`preview_algorithm.py` is a line-for-line port of `AmbienceComposer::compose()`.
It exists so the maths can be checked without a build-deploy cycle. **If you
change the C++, change it too** — it is the cheapest way to see what an edit
does, and it also prints a geometry assertion that the photo really does land
inside the strip.

## Layout

```
harbour-fiatmargo.pro          REQUIRED_FILES guard, explicit $$PWD installs
harbour-fiatmargo.desktop      sailjail Exec, no X-Nemo-Application-Type
rpm/harbour-fiatmargo.spec     %qmake5, never %qtc_*
src/
  harbour-fiatmargo.cpp        main(); seeds the screen ratio, context property
  ambiencecomposer.{h,cpp}     all of the actual work
  previewprovider.{h,cpp}      hands previews to QML without touching disk
qml/
  qmldir                       singleton registration -- must be in DISTFILES
  FiatMargoTheme.qml           fiat colours; accent #1F6E7B deep sea
  harbour-fiatmargo.qml        ApplicationWindow
  components/                  PageHead, SectionLabel, EmptyNote, FiatPill
  pages/                       MainPage, AboutPage, PickerPage
  cover/CoverPage.qml
icons/{86,108,128,172}/
tools/
```

## Harbour notes

- Package, binary, desktop file and icons are all named `harbour-fiatmargo`
  from the start.
- QML imports used: `QtQuick`, `Sailfish.Silica`, `Sailfish.Pickers`,
  `Nemo.Configuration` — all four are on the allowlist.
- Nothing here touches privileged data, so no `Privileged` — which is just as
  well, since that one is not usually accepted for Store submissions.
- `Sailfish.Pickers` is imported in `PickerPage.qml` and nowhere else. An
  import that fails takes down the file it is written in, and the worst case
  should be "choosing a photo stopped working", not a white screen.
- Sailjail declares `Pictures;MediaIndexing`. **Both are required.**
  `Pictures.permission` whitelists the `~/Pictures` directory and nothing
  else; listing photos in the picker goes through tracker over D-Bus, and only
  `MediaIndexing.permission` grants
  `dbus-user.talk org.freedesktop.Tracker3.Miner.Files`. With `Pictures`
  alone the app runs fine from Qt Creator (unsandboxed) and shows an empty
  picker when launched from the icon.

## Licence

MIT.
