import QtQuick 2.0
import Sailfish.Silica 1.0
// A qmldir singleton is NOT picked up by the implicit import of its own
// directory -- it has to be imported explicitly, even from a file sitting
// right beside it. Without this line every FiatMargoTheme reference in THIS
// file is a ReferenceError, while the pages (which all say import "..") work
// fine, so the app comes up looking almost right.
import "."
import "pages"
import "cover"

ApplicationWindow {
    id: app

    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // Setting the palette on the ApplicationWindow is necessary and NOT
    // sufficient: a page inherits the palette it was BUILT with, so a page
    // pushed after the switch was thrown carries the old one until the app
    // restarts. Every page paints itself too -- see paint() in each page.
    Component.onCompleted: FiatMargoTheme.applyPalette(app)

    Connections {
        target: FiatMargoTheme
        onAmbientChanged: FiatMargoTheme.applyPalette(app)
    }
}
