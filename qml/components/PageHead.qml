import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * Replaces Silica's PageHeader, which draws its title in Theme.highlightColor
 * and cannot be recoloured -- under fiat colours over a dark ambience that is
 * bright text on cream paper.
 *
 * Replacing it means inheriting the notch. Three rules:
 *
 *   1. ONE shared component, not a block copied into every page.
 *   2. The title hangs from the TOP of the band, never bottom-aligned. With
 *      bottom alignment a page that has a subtitle pushes its title up, so
 *      every page sits at a slightly different height and it reads as a bug
 *      you cannot name.
 *   3. Corners are free; the middle is not. The cutout is centred, so the
 *      wordmark takes NO inset and instead centres on the system indicator
 *      row. Only the title takes the clearance, and its width is capped so a
 *      long name cannot grow leftwards into the hole.
 */
Item {
    id: head

    property string title
    property string subtitle
    property bool showWordmark: true

    width: parent ? parent.width : 0
    height: contentColumn.y + contentColumn.height + Theme.paddingLarge

    Text {
        id: wordmark
        visible: head.showWordmark
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.top: parent.top
        anchors.topMargin: Math.max(0, FiatMargoTheme.statusRowCenter - height / 2)
        text: "fiat margo"
        color: FiatMargoTheme.primaryText
        font.pixelSize: Theme.fontSizeLarge
        font.family: FiatMargoTheme.serif
        font.italic: true
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.rightMargin: Theme.horizontalPageMargin
        y: head.showWordmark
           ? wordmark.y + wordmark.height + Theme.paddingLarge
           : FiatMargoTheme.headerTopInset
        spacing: Theme.paddingSmall

        Text {
            width: parent.width
            text: head.title
            visible: text !== ""
            color: FiatMargoTheme.primaryText
            font.pixelSize: Theme.fontSizeExtraLarge
            font.family: FiatMargoTheme.serif
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            width: parent.width
            text: head.subtitle
            visible: text !== ""
            color: FiatMargoTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }
    }
}
