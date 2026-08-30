import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

/*
 * A cover is a tile seen at arm's length, not a page. Everything is centred,
 * the wordmark goes at the FOOT as a signature rather than in the corner, and
 * the figure is what the cover is for.
 *
 * `composer` is a context property set in main(), which is the only clean way
 * for the cover and the page to share one instance -- the cover is loaded by
 * URL and cannot see ids declared in the app's root QML.
 */
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

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.paddingLarge * 2
        spacing: Theme.paddingMedium

        // The thing itself: the square as Gallery will see it, with the strip
        // that survives marked out.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, cover.height * 0.42)
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

        // Drawn, not typed. A Rectangle with radius width/2 is round on every
        // font; a bullet glyph is not.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !composer.hasSource
            width: cover.height * 0.16
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

    // The signature.
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingMedium
        horizontalAlignment: Text.AlignHCenter
        text: "fiat margo"
        color: FiatMargoTheme.secondaryText
        font.pixelSize: Theme.fontSizeTiny
        font.family: FiatMargoTheme.serif
        font.italic: true
    }
}
