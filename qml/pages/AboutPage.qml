import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// What it is, how it works, what it will not do, who made it, and where it came
// from. In that order, and nothing else. No changelog -- that belongs in the
// store listing and the repository, where it can be corrected. No donation
// button. Two links.
//
// The lead is one concrete failure rather than a summary. "Prepares a photo for
// use as an ambience" is accurate and says nothing; a photograph of your son
// reduced to the side of his nose says the same thing and can be pictured.
//
// The privacy section is the only place in the app that makes a claim about
// itself, so it is written flat. It also explains WHY the media index
// permission is needed -- that is the one permission a careful reader would
// otherwise be right to be suspicious of, and the real reason is more
// reassuring than silence.

Page {
    id: page

    allowedOrientations: Orientation.Portrait

    // A page inherits the palette it was BUILT with, so every page paints
    // itself. Without this, a page pushed after the fiat colours switch was
    // thrown keeps the old palette until the app restarts.
    function paint() { FiatMargoTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections {
        target: FiatMargoTheme
        onAmbientChanged: page.paint()
    }

    // fiat colours paint their own paper. Under an ambience there is no
    // background at all -- the wallpaper is the background.
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
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            // The wordmark inside PageHead already says "fiat margo", so no
            // subtitle -- it would only say it twice.
            PageHead {
                title: qsTr("about")
            }

            // -- What it is -------------------------------------------------

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatMargoTheme.serif
                color: FiatMargoTheme.primaryText
                text: qsTr("You photograph your kid. Sailfish makes it an ambience. You get the side of his nose.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: qsTr("fiat margo is the step in between. It pads the photo out so that everything the crop throws away is fill rather than photograph, and the picture you framed is the picture you end up looking at.")
            }

            // -- What Sailfish does -----------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("What Sailfish does")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("A photo is cropped <b>twice</b> on its way to becoming an ambience. First it is forced into a <b>square</b>. Then that square is stretched to the height of the screen, and the <b>left and right edges are sliced off</b> to match the screen's width.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: qsTr("Neither step shows you what you are getting — the official documentation says so outright. So a normally framed portrait loses its edges twice, and what survives is a sliver of whatever happened to be dead centre.")
            }

            // -- What margo does ---------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("What margo does")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("The opposite. It places the whole, uncropped photo inside the strip that survives <b>both</b> crops, and fills everything around it with colour taken from the photo's own edges. The crop still happens. It just lands on fill instead of on your picture.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("The part people miss: the surviving strip is <b>full height</b>. The fill above and below your photo is not discarded — it is the part you look at every time you glance at your phone. Only the left and right fill is thrown away. That is the whole reason the fill is sampled from your image rather than set to black.")
            }

            // -- What it cannot do --------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("What it cannot do")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: qsTr("Make the ambience for you. margo writes a prepared image to Pictures / Ambiences, and you finish in Gallery — where the ambience button now has nothing left to \"ruin\".")
            }

            // -- The two fills -------------------------------------------------
            //
            // The radii are stated as a fraction of the image width, because
            // that is what they actually are: kSafety-style divisors of the
            // background's own size, not a pixel count. A pixel count would be
            // wrong at every output size but one.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The two fills")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: qsTr("Both are the same construction: extend the photo's edge pixels outward, then blur. The only difference is how far you let them melt.")
            }

            Repeater {
                model: [
                    {
                        name: qsTr("Edge colour"),
                        meta: qsTr("blur 20% of the width"),
                        desc: qsTr("Soft fields of the colours found along each edge. Wins when the edges are busy and a continuation would look like a mistake.")
                    },
                    {
                        name: qsTr("Edge smear"),
                        meta: qsTr("blur 3.5% of the width"),
                        desc: qsTr("Each edge continues outward, row by row. Wins whenever the photo has a horizon, a wall, or any strong horizontal line — it simply carries on.")
                    }
                ]

                Column {
                    x: Theme.horizontalPageMargin
                    width: content.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatMargoTheme.serif
                        color: FiatMargoTheme.primaryText
                        text: modelData.name
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeTiny
                        color: FiatMargoTheme.accent
                        text: modelData.meta
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatMargoTheme.secondaryText
                        text: modelData.desc
                    }
                }
            }

            // -- Controls --------------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Controls")
            }

            Repeater {
                model: [
                    qsTr("<b>Zoom</b> — at 0 the whole photo is visible and you are looking at a lot of fill; at 1 it fills the screen and the edges crop. Around 45% is usually the sweet spot. Pinching the preview does the same thing."),
                    qsTr("<b>Drag</b> the preview to move the photo."),
                    qsTr("<b>Centre</b> puts it back in the middle."),
                    qsTr("<b>Square / On screen</b> switches between what Gallery shows you and what the phone will actually display.")
                ]

                Label {
                    x: Theme.horizontalPageMargin
                    width: content.width - Theme.horizontalPageMargin * 2
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: FiatMargoTheme.secondaryText
                    textFormat: Text.StyledText
                    text: modelData
                }
            }

            // -- The name ---------------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The name")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>fiat</b> — Latin, <i>let there be</i>. From <i>fiat lux</i> in the Vulgate: let there be light, and there was light. The first app took the phrase. The rest of the family kept the verb.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>margo</b> — Latin, <i>margin, edge, border</i>. The blank a page keeps around its own text, so that the words are never cut by the paper.")
            }

            // -- The motto -----------------------------------------------------
            //
            // Genuine Ovid, and its original subject is concealing your tricks
            // in courtship rather than anything to do with pictures. It earns
            // its place anyway: the fill works exactly as long as nobody
            // notices it, and stops working the moment they do.

            Item { width: 1; height: Theme.paddingMedium }

            Rectangle {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                height: mottoColumn.height + Theme.paddingLarge * 2
                radius: FiatMargoTheme.cardRadius
                color: FiatMargoTheme.card
                border.color: FiatMargoTheme.cardBorder
                border.width: FiatMargoTheme.cardBorderWidth

                Column {
                    id: mottoColumn
                    anchors.centerIn: parent
                    width: parent.width - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatMargoTheme.serif
                        font.italic: true
                        color: FiatMargoTheme.primaryText
                        text: "Si latet, ars prodest"
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatMargoTheme.secondaryText
                        text: qsTr("If it lies hidden, the art works.")
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeTiny
                        color: FiatMargoTheme.secondaryText
                        opacity: 0.75
                        text: "Ovid, Ars Amatoria II"
                    }
                }
            }

            // -- Privacy --------------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Your data")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: qsTr("Everything happens on this phone. There is no account, no network access, and nothing is measured or reported.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("fiat margo asks for two permissions. <b>Pictures</b>, so it can read the photo you choose and write the prepared one back. And <b>Media index</b>, so the picker can list your photos at all — without it the sandbox lets the app see the folder but not ask what is in it.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: qsTr("Your original is never touched. margo only ever writes a new file into Pictures / Ambiences, named after the photo it came from.")
            }

            // -- Who -------------------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Made by")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatMargoTheme.serif
                color: FiatMargoTheme.primaryText
                text: "Munkstolen"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatMargoTheme.secondaryText
                text: "Caesar Prometheus Ivarsson"
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatMargoTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://munkstolen.se")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatMargoTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "munkstolen.se"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatMargoTheme.secondaryText
                        text: qsTr("Everything else I make")
                    }
                }
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatMargoTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://github.com/munksh/FiatMargo")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatMargoTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "github.com/munksh/FiatMargo"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatMargoTheme.secondaryText
                        text: qsTr("Source and issues · MIT licence")
                    }
                }
            }

            // -- The family --------------------------------------------------------
            //
            // Every name translates itself, and the translation explains the
            // app. That is worth more than a tagline.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The fiat family")
            }

            Repeater {
                model: [
                    { name: "fiat lux",    what: qsTr("let there be light — a light meter for film"),        me: false },
                    { name: "fiat vox",    what: qsTr("let there be voice — a chromatic tuner"),             me: false },
                    { name: "fiat mos",    what: qsTr("let there be habit — a habit tracker"),               me: false },
                    { name: "fiat agenda", what: qsTr("let there be things to be done — a task list"),       me: false },
                    { name: "fiat margo",  what: qsTr("let there be a margin — this one"),                   me: true }
                ]

                Column {
                    x: Theme.horizontalPageMargin
                    width: content.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: FiatMargoTheme.serif
                        color: modelData.me ? FiatMargoTheme.accent : FiatMargoTheme.primaryText
                        text: modelData.name
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatMargoTheme.secondaryText
                        text: modelData.what
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeTiny
                color: FiatMargoTheme.secondaryText
                text: qsTr("Instruments for things you would otherwise guess at. They share a look, a palette, and a stubbornness about staying on your own phone.")
            }

            // -- Version -----------------------------------------------------------
            //
            // Last, because it is support and not identity. The number comes
            // from the rpm spec by way of qmake, so it is the one the package
            // was actually built with rather than one written down twice.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Version")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeSmall
                color: FiatMargoTheme.primaryText
                text: typeof appVersion !== "undefined" ? appVersion : qsTr("unknown")
            }

            // -- Colophon ------------------------------------------------------
            //
            // A printer's mark at the end of a book: a short rule, the mark,
            // the wordmark. Nothing here is tappable -- the links are up under
            // "made by". This is the signature, not a button.

            Item { width: 1; height: Theme.itemSizeExtraSmall }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatMargoTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingLarge }

            MunkstolenMark {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeMedium
                frame: "ring"
                color: FiatMargoTheme.makerMark
            }

            Item { width: 1; height: Theme.paddingSmall }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "munkstolen"
                font.pixelSize: Theme.fontSizeSmall
                font.family: FiatMargoTheme.serif
                font.italic: true
                color: FiatMargoTheme.makerMark
            }
        }

        VerticalScrollDecorator { }
    }
}
