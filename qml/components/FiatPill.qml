import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// A choice written as a word. Still called FiatPill so every page that uses it
// keeps its shape, but it no longer draws one: it follows Fiat Ratio's
// WordChoice. The chosen word is in the accent, bold, with a bar under it;
// the others are grey. No frame, so a row of them reads as one line of text
// and not as a row of buttons. Wrap them in a Flow, not a Grid.
//
//   one of a few   FiatPill { label: "All"; selected: x === 2 }
//                  The bar says "this one, and only this one".
//
//   several        FiatPill { multi: true; label: "french"; selected: ... }
//                  Bold and in the accent, but no bar -- the bar means
//                  "one of", and here any number can be on.
//
// Something that DOES a thing rather than picks a value is not a FiatPill. That
// is an ActionWord.
//
// The word is measured in bold whatever state it is in, so choosing one does
// not nudge the others sideways.

MouseArea {
    id: root

    // Margo's own names: `label` for the word, and `clicked()` from the MouseArea.
    property string label: ""
    property string text: root.label
    property bool selected: false
    property bool multi: false

    // A long word -- a book title, a tag -- is shortened rather than allowed to
    // push the Flow wider than the page.
    readonly property real roomForText: Math.max(Theme.itemSizeSmall,
        (parent ? parent.width : Theme.itemSizeHuge * 3) - Theme.paddingMedium * 2)

    implicitWidth: Math.min(sizer.implicitWidth, roomForText) + Theme.paddingMedium * 2
    implicitHeight: Theme.itemSizeExtraSmall
    width: implicitWidth
    height: implicitHeight

    Label {
        id: sizer
        visible: false
        text: root.text
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.paddingSmall
        color: FiatMargoTheme.highlightWash
        visible: root.pressed && root.containsMouse
    }

    Label {
        id: wordLabel
        anchors.centerIn: parent
        width: Math.min(sizer.implicitWidth, root.roomForText)
        horizontalAlignment: Text.AlignHCenter
        truncationMode: TruncationMode.Fade
        text: root.text
        font.pixelSize: Theme.fontSizeSmall
        font.bold: root.selected
        color: root.selected ? FiatMargoTheme.accent : FiatMargoTheme.secondaryText
    }

    Rectangle {
        visible: root.selected && !root.multi
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: wordLabel.bottom
        anchors.topMargin: Theme.paddingSmall / 2
        width: Math.min(wordLabel.implicitWidth, wordLabel.width)
        height: Math.max(2, Theme.paddingSmall / 2)
        color: FiatMargoTheme.accent
    }
}
