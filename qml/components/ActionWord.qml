import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// A word that does something: "look up", "use this kind". Bold, in the
// accent, nothing around it -- the same voice as Save in the dialog header.
// Not a Pill: a Pill picks a value and stays picked; this happens once.
//
// Sailfish has few buttons. Most actions are a row you tap or a pull-down
// item; this is for the handful that belong right beside what they act on.

MouseArea {
    id: root

    property string text: ""
    // The verdict colour, for the one action that cannot be taken back.
    property bool danger: false
    // Grey and not bold: the way out, beside the way on ("cancel").
    property bool quiet: false

    implicitWidth: label.implicitWidth + Theme.paddingMedium * 2
    implicitHeight: Theme.itemSizeExtraSmall
    width: implicitWidth
    height: implicitHeight
    opacity: enabled ? 1.0 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: Theme.paddingSmall
        color: FiatMargoTheme.highlightWash
        visible: root.pressed && root.containsMouse
    }

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Theme.fontSizeSmall
        font.bold: !root.quiet
        color: root.danger ? FiatMargoTheme.wrong : (root.quiet ? FiatMargoTheme.secondaryText : FiatMargoTheme.accent)
    }
}
