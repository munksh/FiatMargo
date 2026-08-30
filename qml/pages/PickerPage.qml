import QtQuick 2.0
import Sailfish.Pickers 1.0

/*
 * The image picker lives in its own file on purpose.
 *
 * Sailfish.Pickers is on the Harbour allowlist and ships with the OS, but an
 * import that fails takes down the whole file it is written in. Kept here,
 * the worst case is that choosing a photo stops working; kept in MainPage, the
 * worst case is a white screen.
 *
 * `composer` is a context property set in main(), so this page can hand the
 * choice over directly without a signal chain back through pageStack.
 */
ImagePickerPage {
    title: "Choose a photo"

    onSelectedContentChanged: {
        if (selectedContent) {
            composer.sourcePath = selectedContent
        }
    }
}
