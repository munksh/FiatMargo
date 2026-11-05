import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.Portrait

    property real hue: 0.0
    property real saturation: 0.0
    property real lightness: 0.25

    readonly property color colour: Qt.hsla(hue, saturation, lightness, 1.0)

    function hex2(v) {
        var s = Math.round(v * 255).toString(16)
        return s.length < 2 ? "0" + s : s
    }
    function hexOf(c) { return ("#" + hex2(c.r) + hex2(c.g) + hex2(c.b)).toUpperCase() }

    // QML's color type has no HSL accessors on this Qt, so the conversion is
    // done here. Grey has no hue; keep the one already set rather than
    // jumping the slider to 0.
    function takeColour(c) {
        var r = c.r, g = c.g, b = c.b
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var l = (max + min) / 2
        var s = 0
        var h = page.hue
        if (max !== min) {
            var d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            if (max === r)      h = ((g - b) / d + (g < b ? 6 : 0)) / 6
            else if (max === g) h = ((b - r) / d + 2) / 6
            else                h = ((r - g) / d + 4) / 6
        }
        page.hue = h
        page.saturation = s
        page.lightness = l
        hueSlider.pull(h)
        satSlider.pull(s)
        lightSlider.pull(l)
    }

    function paint() { FiatMargoTheme.applyPalette(page) }
    Component.onCompleted: {
        paint()
        takeColour(composer.solidColour)
        hexField.text = hexOf(page.colour)
    }
    Connections {
        target: FiatMargoTheme
        onAmbientChanged: page.paint()
    }

    Rectangle {
        anchors.fill: parent
        visible: !FiatMargoTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatMargoTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatMargoTheme.backgroundLow }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge * 2

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHead {
                title: "colour"
                subtitle: "One colour, edge to edge. Nothing in it can be cropped."
            }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                height: width * 0.6
                radius: FiatMargoTheme.cardRadius
                color: page.colour
                border.color: FiatMargoTheme.cardBorder
                border.width: FiatMargoTheme.cardBorderWidth
            }

            /*
             * No binding on `value` -- see the zoom slider on MainPage. Each
             * slider seeds itself through pull() and pushes changes out; the
             * flag keeps a pull from looking like a drag.
             */
            Column {
                width: parent.width

                Slider {
                    id: hueSlider
                    width: parent.width
                    label: "Hue"
                    minimumValue: 0.0
                    maximumValue: 1.0
                    stepSize: 1 / 360
                    valueText: Math.round(value * 360) + "°"
                    property bool syncing: false
                    function pull(v) { syncing = true; value = v; syncing = false }
                    onValueChanged: if (!syncing) page.hue = value
                }

                Slider {
                    id: satSlider
                    width: parent.width
                    label: "Saturation"
                    minimumValue: 0.0
                    maximumValue: 1.0
                    stepSize: 0.01
                    valueText: Math.round(value * 100) + "%"
                    property bool syncing: false
                    function pull(v) { syncing = true; value = v; syncing = false }
                    onValueChanged: if (!syncing) page.saturation = value
                }

                Slider {
                    id: lightSlider
                    width: parent.width
                    label: "Lightness"
                    minimumValue: 0.0
                    maximumValue: 1.0
                    stepSize: 0.01
                    valueText: Math.round(value * 100) + "%"
                    property bool syncing: false
                    function pull(v) { syncing = true; value = v; syncing = false }
                    onValueChanged: if (!syncing) page.lightness = value
                }
            }

            TextField {
                id: hexField
                width: parent.width
                label: "Hex"
                placeholderText: "#RRGGBB"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                validator: RegExpValidator { regExp: /#?[0-9A-Fa-f]{6}/ }

                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    var t = text.charAt(0) === "#" ? text : "#" + text
                    page.takeColour(Qt.lighter(t, 1.0))
                    focus = false
                }

                Connections {
                    target: page
                    onColourChanged: {
                        if (!hexField.activeFocus) {
                            hexField.text = page.hexOf(page.colour)
                        }
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Use this colour"
                onClicked: {
                    composer.setSolid(page.colour)
                    pageStack.pop()
                }
            }
        }

        VerticalScrollDecorator { }
    }
}
