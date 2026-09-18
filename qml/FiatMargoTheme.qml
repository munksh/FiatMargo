pragma Singleton

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

/*
 * fiat colours -- the family standard. Two palettes behind one set of names,
 * switched by a single boolean.
 *
 *   ambient = true   everything comes from the user's ambience via Theme.*,
 *                    and NO background is painted: the wallpaper is the
 *                    background.
 *   ambient = false  fiat colours. The app paints its own paper and uses the
 *                    family palette.
 *
 * Semantic colours ignore both. They mean something, so they only ever shift
 * between a dark and a light variant to keep contrast.
 */
QtObject {
    id: theme

    // ---- the switch, remembered between runs ----
    property ConfigurationValue ambientConfig: ConfigurationValue {
        key: "/apps/fiatmargo/ambient"
        defaultValue: true
    }
    readonly property bool ambient: ambientConfig.value
    function setAmbient(on) { ambientConfig.value = on }

    // fiat colours are a light scheme, so dark is false there.
    readonly property bool dark: ambient ? (Theme.colorScheme === Theme.LightOnDark) : false

    readonly property string serif: "Georgia"

    // ---- the family palette ----
    readonly property color primaryText:   ambient ? Theme.primaryColor   : "#1A1A1A"
    readonly property color secondaryText: ambient ? Theme.secondaryColor : Qt.rgba(0.10, 0.10, 0.10, 0.55)

    // Deep sea. Contrast 5.12 on the fiat paper, which puts margo between
    // vox (4.97) and mos (5.24). Teal rather than blue or green so it is
    // mistaken for neither sibling, and nowhere near the red that means a
    // photo is too small.
    readonly property color accent: ambient ? Theme.highlightColor : "#716A00"

    readonly property color backgroundHigh: "#F2EFE8"
    readonly property color backgroundLow:  "#D8D2C6"

    readonly property color card: ambient
        ? (dark ? Qt.rgba(0.08, 0.08, 0.08, 1.0) : Qt.rgba(0.96, 0.96, 0.96, 1.0))
        : "#F5F5F5"
    readonly property color surface: card

    readonly property color cardBorder:   Theme.rgba(primaryText, 0.45)
    readonly property color innerBorder:  Theme.rgba(primaryText, 0.22)
    readonly property color recessFill:   Theme.rgba(primaryText, 0.05)
    readonly property color recessBorder: Theme.rgba(primaryText, 0.16)
    readonly property real cardRadius: Theme.paddingLarge * 2
    readonly property int cardBorderWidth: 2

    // The wash behind a pressed BackgroundItem. Silica's own default is drawn
    // from the ambience and ignores fiat colours entirely.
    readonly property color highlightWash: Theme.rgba(accent, 0.15)

    // The colophon: the maker's mark and the signature under it. Quieter than
    // secondaryText on purpose -- a signature is not a heading, and it should
    // not compete with the content above it.
    readonly property color makerMark: Theme.rgba(primaryText, 0.45)

    readonly property color pillFill:         Theme.rgba(primaryText, 0.15)
    readonly property color pillBorder:       Theme.rgba(primaryText, 0.55)
    readonly property color pillFillActive:   Theme.rgba(accent, 0.15)
    readonly property color pillBorderActive: Theme.rgba(accent, 0.45)

    /*
     * margo has exactly ONE semantic colour, and it took some arguing to get
     * there. A verdict, not a state:
     *
     *   the chosen fill mode  -> a state       -> accent
     *   a saved image         -> a state       -> accent
     *   "this photo does not have the pixels"  -> a VERDICT about the photo,
     *                                             which is the one thing the
     *                                             app is qualified to judge
     */
    readonly property color wrong: dark ? "#A0403A" : "#8A2B25"

    // ---- the notch, and headers we draw ourselves ----
    //
    // Read from the platform when the platform will say. Asking a QObject for
    // a property it does not have returns undefined rather than throwing, so
    // the probe is safe -- but the fallback has to be a real number.
    function cutoutHeight() {
        if (typeof Screen === "undefined" || Screen === null) return -1
        var c = Screen.topCutout
        if (c === undefined || c === null) return -1
        if (typeof c === "number") return c
        if (c.height !== undefined) return c.height
        return -1
    }

    readonly property real headerTopInsetFallback: Theme.paddingLarge * 1.5
    readonly property real headerTopInset: {
        var c = cutoutHeight()
        return c >= 0 ? c + Theme.paddingMedium : headerTopInsetFallback
    }

    // Where the system's own indicators sit. Silica does not publish this.
    // itemSizeLarge / 2, written down and NOT derived -- two attempts at
    // computing it from the cutout walked the wordmark up the screen, and
    // "fiat margo" is ten characters, which is the length that needs the room.
    readonly property real statusRowCenter: Theme.itemSizeLarge / 2

    /*
     * Silica's own chrome. fiat colours only reach what the app draws itself;
     * menus, sliders, ComboBox values and the virtual keyboard read Theme.*
     * directly, which is the ambience. Setting the palette once on an item
     * fixes every Silica control below it.
     *
     * Assign the roles from JavaScript, never from a binding: a missing
     * property assigned in a binding is a load-time error and the whole page
     * dies silently, while from JS it is a no-op that try/catch mops up. The
     * roles are not guaranteed to exist on every Silica version.
     */
    function applyPalette(item) {
        if (item === null || item === undefined) return
        var p = item.palette
        if (p === undefined || p === null) return
        try { p.colorScheme = ambient ? Theme.colorScheme : Theme.DarkOnLight } catch (e) { }
        try { p.primaryColor = primaryText } catch (e) { }
        try { p.secondaryColor = secondaryText } catch (e) { }
        try { p.highlightColor = accent } catch (e) { }
        try { p.secondaryHighlightColor = Theme.rgba(accent, 0.6) } catch (e) { }
        // NOT the accent. This role is what the virtual keyboard paints its
        // keys with. 30% of an accent over light paper turns the whole
        // keyboard that colour -- a neutral wash serves both modes and shouts
        // in neither.
        try { p.highlightBackgroundColor = Theme.rgba(primaryText, 0.12) } catch (e) { }
        try { p.errorColor = wrong } catch (e) { }
        try { p.highlightDimmerColor = ambient ? Theme.highlightDimmerColor : backgroundLow } catch (e) { }
        try { p.overlayBackgroundColor = ambient ? Theme.overlayBackgroundColor : backgroundHigh } catch (e) { }
    }
    // Cover layout
    readonly property real coverWordmarkTop: Theme.paddingLarge
    readonly property real coverSideMargin: Theme.paddingLarge
    readonly property real coverFigureFraction: 0.28
}
