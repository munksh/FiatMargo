import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.Portrait

    readonly property int fillEdgeColour: 0
    readonly property int fillEdgeSmear: 1

    property bool stripMode: false
    property string saveError: ""

    // A photo was chosen but could not be decoded.
    readonly property bool loadFailed: composer.sourcePath !== "" && !composer.hasSource

    function paint() { FiatMargoTheme.applyPalette(page) }
    Component.onCompleted: paint()
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
        id: flick
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge * 2

        PullDownMenu {
            // Never set backgroundColor here: it paints the whole panel and
            // dims the entire screen behind the menu.
            highlightColor: FiatMargoTheme.accent
            MenuItem {
                text: "About"
                color: FiatMargoTheme.primaryText
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: FiatMargoTheme.ambient ? "fiat colours" : "Follow ambience"
                color: FiatMargoTheme.primaryText
                onClicked: FiatMargoTheme.setAmbient(!FiatMargoTheme.ambient)
            }
            MenuItem {
                text: "Start over"
                color: FiatMargoTheme.primaryText
                visible: composer.hasSource
                onClicked: composer.clear()
            }
            MenuItem {
                text: "Choose a photo"
                color: FiatMargoTheme.primaryText
                onClicked: pageStack.push(Qt.resolvedUrl("PickerPage.qml"))
            }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHead {
                subtitle: composer.hasSource
                          ? "Drag to move the photo, pinch to zoom. The dimmed edges are what Sailfish throws away."
                          : ""
            }

            /*
             * ---------------- empty state ----------------
             *
             * This used to be a Column with anchors.centerIn inside an Item
             * whose height came from that same Column. The value was not
             * actually circular, but QML's dependency tracker still saw
             * parent.height <- child.height and child.y <- parent.height,
             * broke the loop, and left the Item zero-high. The result was a
             * blank page with the "Choose a photo" button rendered but
             * unreachable -- which is exactly what you get on every launch,
             * because nothing persists the chosen photo.
             *
             * No wrapper, no centring. A Column in a Column, positioned by
             * the parent, nothing depending on anything below it.
             */
            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                spacing: Theme.paddingLarge * 2
                visible: !composer.hasSource

                Item { width: 1; height: Theme.paddingLarge * 2 }

                EmptyNote {
                    width: parent.width
                    title: page.loadFailed ? "Could not read that photo" : "no photo yet"
                    hint: page.loadFailed
                          ? "Try another one — margo reads JPEG and PNG."
                          : "You photograph your kid. Sailfish makes it an ambience. "
                            + "You get the side of his nose.\n\n"
                            + "margo is the step in between. It pads the photo out first, so "
                            + "the crop lands on fill instead of on your picture."
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Choose a photo"
                    onClicked: pageStack.push(Qt.resolvedUrl("PickerPage.qml"))
                }
            }

            // ---------------- the preview card ----------------
            Item {
                width: parent.width
                height: card.height
                visible: composer.hasSource

                Rectangle {
                    id: card
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    height: stage.height + Theme.paddingLarge * 2
                    radius: FiatMargoTheme.cardRadius
                    color: FiatMargoTheme.card
                    border.color: FiatMargoTheme.cardBorder
                    border.width: FiatMargoTheme.cardBorderWidth

                    Item {
                        id: stage
                        x: Theme.paddingLarge
                        y: Theme.paddingLarge
                        width: card.width - Theme.paddingLarge * 2
                        // In strip mode the stage takes the phone's own shape.
                        height: page.stripMode
                                ? width / Math.max(0.2, composer.effectiveAspect)
                                : width
                        clip: true

                        // The composed square. In strip mode it is blown up so
                        // that the surviving strip exactly fills the stage, and
                        // the clip does what Sailfish's second crop does.
                        Image {
                            id: preview
                            anchors.centerIn: parent
                            width: page.stripMode
                                   ? stage.width / Math.max(0.2, composer.effectiveAspect)
                                   : stage.width
                            height: width
                            source: composer.hasSource
                                    ? "image://margo/preview?" + composer.revision
                                    : ""
                            cache: false
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                        }

                        // What Sailfish discards, dimmed. Only meaningful while
                        // looking at the square.
                        Item {
                            anchors.fill: preview
                            visible: !page.stripMode

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (1 - composer.effectiveAspect) / 2
                                color: Qt.rgba(0, 0, 0, 0.45)
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (1 - composer.effectiveAspect) / 2
                                color: Qt.rgba(0, 0, 0, 0.45)
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

                        /*
                         * Pinch to zoom, drag to move.
                         *
                         * PinchArea is plain QtQuick, so unlike the Slider
                         * below there is no question about which property it
                         * updates or when. If the slider ever misbehaves on a
                         * different Silica version, this still works.
                         */
                        PinchArea {
                            anchors.fill: parent
                            property real startZoom: 0

                            onPinchStarted: {
                                startZoom = composer.zoom
                                composer.beginInteraction()
                            }
                            onPinchUpdated: composer.zoom = startZoom + (pinch.scale - 1.0) * 0.7
                            onPinchFinished: composer.endInteraction()

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                property real startX
                                property real startY
                                property real startOffsetX
                                property real startOffsetY

                                onPressed: {
                                    startX = mouse.x
                                    startY = mouse.y
                                    startOffsetX = composer.offsetX
                                    startOffsetY = composer.offsetY
                                    composer.beginInteraction()
                                }
                                onPositionChanged: {
                                    if (preview.width <= 0) return
                                    composer.offsetX = startOffsetX + (mouse.x - startX) / preview.width
                                    composer.offsetY = startOffsetY + (mouse.y - startY) / preview.width
                                }
                                // Both, or a gesture stolen by the flickable
                                // leaves the preview stuck at draft quality.
                                onReleased: composer.endInteraction()
                                onCanceled: composer.endInteraction()
                            }
                        }
                    }
                }
            }

            // ---------------- what you are looking at ----------------
            Flow {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                spacing: Theme.paddingMedium
                visible: composer.hasSource

                FiatPill {
                    label: "Square"
                    selected: !page.stripMode
                    onClicked: page.stripMode = false
                }
                FiatPill {
                    label: "On screen"
                    selected: page.stripMode
                    onClicked: page.stripMode = true
                }

                // Not a mode, so it never reads as selected -- it is an
                // action that puts the photo back in the middle after a drag.
                FiatPill {
                    label: "Centre"
                    selected: false
                    opacity: composer.centred ? 0.4 : 1.0
                    onClicked: composer.centre()
                }
            }

            // ---------------- controls ----------------
            Column {
                width: parent.width
                spacing: Theme.paddingLarge
                visible: composer.hasSource

                // ---- fill ----
                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    spacing: Theme.paddingMedium

                    SectionLabel { text: "FILL"; width: parent.width }

                    Flow {
                        width: parent.width
                        spacing: Theme.paddingMedium

                        FiatPill {
                            label: "Edge colour"
                            selected: composer.fillMode === page.fillEdgeColour
                            onClicked: composer.fillMode = page.fillEdgeColour
                        }
                        FiatPill {
                            label: "Edge smear"
                            selected: composer.fillMode === page.fillEdgeSmear
                            onClicked: composer.fillMode = page.fillEdgeSmear
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: FiatMargoTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: composer.fillMode === page.fillEdgeColour
                              ? "Soft fields of the colours found along each edge."
                              : "Each edge continues outward, row by row."
                    }
                }

                // ---- zoom ----
                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    spacing: Theme.paddingSmall

                    SectionLabel { text: "ZOOM"; width: parent.width }

                    /*
                     * Do NOT put a binding on `value`.
                     *
                     * Silica's Slider assigns to its own `value` while the
                     * handle is dragged. An external binding (value:
                     * composer.zoom) wins that fight: the handle moves,
                     * `value` stays pinned to composer.zoom, onValueChanged
                     * never fires, and the whole control does nothing at all.
                     * That is the bug this replaces.
                     *
                     * So: no binding. Seed it once, push changes out, and pull
                     * changes back in only when they came from elsewhere. The
                     * `syncing` flag keeps the write-back from looking like
                     * user input.
                     */
                    Slider {
                        id: zoomSlider
                        width: parent.width
                        minimumValue: 0.0
                        maximumValue: 1.0
                        stepSize: 0.01
                        property bool syncing: false

                        valueText: value < 0.02
                                   ? "Whole photo"
                                   : (value > 0.98 ? "Fills the screen"
                                                   : Math.round(value * 100) + "%")

                        Component.onCompleted: {
                            syncing = true
                            value = composer.zoom
                            syncing = false
                        }

                        onValueChanged: {
                            if (!syncing) {
                                composer.zoom = value
                            }
                        }

                        Connections {
                            target: composer
                            onSettingsChanged: {
                                if (Math.abs(zoomSlider.value - composer.zoom) > 0.005) {
                                    zoomSlider.syncing = true
                                    zoomSlider.value = composer.zoom
                                    zoomSlider.syncing = false
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: FiatMargoTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: "At 0 the whole photo is visible and you are looking at a lot of "
                              + "fill. Around 45% is usually the sweet spot. You can pinch the "
                              + "preview instead."
                    }
                }

                // ---- the photo ----
                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    spacing: Theme.paddingSmall

                    SectionLabel { text: "PHOTO"; width: parent.width }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: FiatMargoTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: composer.sourceWidth + " by " + composer.sourceHeight
                              + ", saved at " + composer.outputSize + " square."
                    }

                    // The one verdict this app is qualified to make.
                    Text {
                        width: parent.width
                        visible: composer.tooSmall
                        wrapMode: Text.WordWrap
                        color: FiatMargoTheme.wrong
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: "This photo does not have the pixels for "
                              + composer.outputSize
                              + ". It will be enlarged to fit and will look soft on the lock screen."
                    }
                }
            }

            // ---------------- save ----------------
            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: composer.hasSource

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: composer.busy ? "Saving..." : "Save to Gallery"
                    enabled: !composer.busy
                    onClicked: composer.save()
                }

                Text {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    visible: composer.savedCount > 0 && page.saveError === ""
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: FiatMargoTheme.accent
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: "Saved to Pictures / Ambiences. Open it in Gallery and tap the "
                          + "ambience button -- nothing important is left in the crop zone now."
                }

                Text {
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    visible: page.saveError !== ""
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: FiatMargoTheme.wrong
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: page.saveError
                }

                Item { width: 1; height: Theme.paddingLarge }
            }
        }

        VerticalScrollDecorator { }
    }

    Connections {
        target: composer
        onSaveFailed: page.saveError = reason
        onSavedCountChanged: page.saveError = ""
        onSourceChanged: page.saveError = ""
    }
}
