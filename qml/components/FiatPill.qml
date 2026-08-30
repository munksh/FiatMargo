import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * The family's toggle for selectable values. Never TextSwitch, which stacks
 * awkwardly. Pills wrap in a Flow, not a Grid, so they reflow to content
 * width.
 */
Rectangle {
    id: pill

    property string label
    property bool selected: false
    signal clicked()

    radius: height / 2
    color: selected ? FiatMargoTheme.pillFillActive : FiatMargoTheme.pillFill
    border.color: selected ? FiatMargoTheme.pillBorderActive : FiatMargoTheme.pillBorder
    border.width: 1

    width: pillText.width + Theme.paddingLarge * 2
    height: pillText.height + Theme.paddingMedium

    Text {
        id: pillText
        anchors.centerIn: parent
        text: pill.label
        color: pill.selected ? FiatMargoTheme.accent : FiatMargoTheme.primaryText
        font.pixelSize: Theme.fontSizeSmall
    }

    MouseArea {
        anchors.fill: parent
        onClicked: pill.clicked()
    }
}
