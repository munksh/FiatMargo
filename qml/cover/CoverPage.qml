import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CoverBackground {
    id: cover

    Rectangle {
        anchors.fill: parent
        visible: !FiatMargoTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatMargoTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatMargoTheme.backgroundLow }
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: FiatMargoTheme.coverWordmarkTop
        text: "fiat margo"
        color: FiatMargoTheme.secondaryText
        font.pixelSize: Theme.fontSizeTiny
        font.family: FiatMargoTheme.serif
        font.italic: true
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: FiatMargoTheme.coverSideMargin
        anchors.rightMargin: FiatMargoTheme.coverSideMargin
        anchors.topMargin: cover.height * FiatMargoTheme.coverFigureFractionShape
        spacing: Theme.paddingMedium

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: cover.width * FiatMargoTheme.coverArtFraction
            height: width
            visible: composer.hasSource

            Image {
                id: thumb
                anchors.fill: parent
                source: composer.hasSource
                        ? "image://margo/preview?" + composer.revision
                        : ""
                cache: false
                asynchronous: true
                fillMode: Image.PreserveAspectFit
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: parent.width * (1 - composer.effectiveAspect) / 2
                width: 1
                color: FiatMargoTheme.accent
            }
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: parent.width - parent.width * (1 - composer.effectiveAspect) / 2 - 1
                width: 1
                color: FiatMargoTheme.accent
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !composer.hasSource
            width: cover.width * FiatMargoTheme.coverArtFraction * 0.4
            height: width
            radius: width / 2
            color: "transparent"
            border.color: FiatMargoTheme.accent
            border.width: 2
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: composer.hasSource ? "ready" : "no photo"
            color: FiatMargoTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }
}
