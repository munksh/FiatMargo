import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * Replaces SectionHeader, which draws its text in Theme.highlightColor and
 * adds a horizontal rule nobody asked for. Set `text` directly -- an alias
 * back to the root item's own property is the kind of thing QML accepts in
 * some versions and refuses in others.
 */
Text {
    color: FiatMargoTheme.secondaryText
    font.pixelSize: Theme.fontSizeExtraSmall
    font.letterSpacing: Theme.pixelRatio * 1.5
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
