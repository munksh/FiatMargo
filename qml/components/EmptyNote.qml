import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * Replaces ViewPlaceholder, which draws its title in Theme.highlightColor and
 * its hint in secondaryHighlightColor -- the one piece of text on an otherwise
 * empty screen, and the one Silica will not let you recolour.
 *
 * Parent this OUTSIDE any ListView. A plain child of a ListView is reparented
 * to its contentItem, which has no height when the model is empty -- exactly
 * when the note needs to be visible.
 */
Column {
    property string title
    property string hint

    spacing: Theme.paddingMedium

    Text {
        width: parent.width
        text: title
        color: FiatMargoTheme.primaryText
        font.pixelSize: Theme.fontSizeLarge
        font.family: FiatMargoTheme.serif
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    Text {
        width: parent.width
        text: hint
        visible: text !== ""
        color: FiatMargoTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
