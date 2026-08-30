# fiat margo -- prepare a photo so Sailfish's ambience cropping cannot eat it.
#
# TARGET and the root QML filename must match. Changing TARGET changes five
# things: qml/<TARGET>.qml, <TARGET>.desktop plus its Icon= and Exec=,
# icons/*/<TARGET>.png, rpm/<TARGET>.spec plus its Name:, and the
# ConfigurationValue key in FiatMargoTheme.qml.

TARGET = harbour-fiatmargo

CONFIG += sailfishapp

QT += core gui quick

# ---------------------------------------------------------------------------
# The version reaches the About page from the rpm spec, by way of qmake, so it
# is the number the package was actually built with rather than one written
# down in two places and kept in step by hand.
#
# sed rather than awk: awk would want $2, and a bare $ in a .pro is one more
# thing to get wrong for no benefit.
# ---------------------------------------------------------------------------
SPEC_FILE = $$PWD/rpm/$${TARGET}.spec
APP_VERSION = $$system(sed -n 's/^Version:[[:space:]]*//p' $${SPEC_FILE} | head -1)
isEmpty(APP_VERSION): APP_VERSION = 0.0.0
DEFINES += APP_VERSION=\\\"$${APP_VERSION}\\\"
message("fiat margo version $${APP_VERSION}")

SOURCES += \
    src/harbour-fiatmargo.cpp \
    src/ambiencecomposer.cpp \
    src/previewprovider.cpp

HEADERS += \
    src/ambiencecomposer.h \
    src/previewprovider.h

DISTFILES += \
    harbour-fiatmargo.desktop \
    rpm/harbour-fiatmargo.spec \
    qml/harbour-fiatmargo.qml \
    qml/qmldir \
    qml/FiatMargoTheme.qml \
    qml/components/PageHead.qml \
    qml/components/SectionLabel.qml \
    qml/components/EmptyNote.qml \
    qml/components/FiatPill.qml \
    qml/components/MunkstolenMark.qml \
    qml/pages/MainPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/PickerPage.qml \
    qml/cover/CoverPage.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# ---------------------------------------------------------------------------
# Fail loudly on a missing file.
#
# Every one of these fails SILENTLY otherwise, and each silent failure looks
# like a completely different bug:
#
#   qml/$${TARGET}.qml missing -> white screen, one [W] File not found
#   $${TARGET}.desktop missing -> qmake drops the install rule, build dies
#                                 200 lines later on an unexpanded glob
#   qml/qmldir missing         -> every page: "FiatMargoTheme is not a type"
#
# A file transferred by hand can arrive renamed -- a browser that eats the
# hyphen out of harbour-fiatmargo.qml is enough -- so check, do not assume.
# ---------------------------------------------------------------------------
REQUIRED_FILES = \
    $${TARGET}.desktop \
    qml/$${TARGET}.qml \
    qml/qmldir \
    qml/FiatMargoTheme.qml \
    qml/pages/MainPage.qml \
    qml/pages/PickerPage.qml \
    qml/pages/AboutPage.qml \
    qml/cover/CoverPage.qml \
    qml/components/MunkstolenMark.qml \
    src/ambiencecomposer.cpp \
    src/previewprovider.cpp

for(f, REQUIRED_FILES) {
    !exists($$PWD/$$f): error("Missing $$f -- expected it at $$PWD/$$f")
}

# ---------------------------------------------------------------------------
# Explicit installs, always with $$PWD.
#
# This is a shadow build. A relative path can resolve against the BUILD
# directory instead of the source tree, and qmake then drops the rule with a
# warning nobody reads -- which shows up much later as a white screen.
# ---------------------------------------------------------------------------
qml_root.files = $$PWD/qml/harbour-fiatmargo.qml $$PWD/qml/qmldir $$PWD/qml/FiatMargoTheme.qml
qml_root.path  = /usr/share/$${TARGET}/qml

qml_components.files = $$files($$PWD/qml/components/*.qml)
qml_components.path  = /usr/share/$${TARGET}/qml/components

qml_pages.files = $$files($$PWD/qml/pages/*.qml)
qml_pages.path  = /usr/share/$${TARGET}/qml/pages

qml_cover.files = $$files($$PWD/qml/cover/*.qml)
qml_cover.path  = /usr/share/$${TARGET}/qml/cover

INSTALLS += qml_root qml_components qml_pages qml_cover
