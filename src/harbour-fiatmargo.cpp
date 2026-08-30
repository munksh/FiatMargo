#include <sailfishapp.h>

#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickView>
#include <QScreen>
#include <QScopedPointer>

#include "ambiencecomposer.h"
#include "previewprovider.h"

// Defined by the .pro, read out of rpm/harbour-fiatmargo.spec. The fallback
// exists so that building this file outside qmake is not a compile error.
#ifndef APP_VERSION
#define APP_VERSION "0.0.0"
#endif

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // The engine takes ownership of an image provider the moment it is added,
    // so this is deliberately never deleted here.
    PreviewProvider *provider = new PreviewProvider;
    view->engine()->addImageProvider(QStringLiteral("margo"), provider);

    AmbienceComposer composer(provider);

    // Seed the screen ratio from the real screen. This is the number that
    // decides how much of the square survives Sailfish's second crop, and
    // getting it from the platform beats asking the user to look it up.
    if (QScreen *screen = QGuiApplication::primaryScreen()) {
        const QSize size = screen->size();
        if (size.width() > 0 && size.height() > 0) {
            const qreal w = qMin(size.width(), size.height());
            const qreal h = qMax(size.width(), size.height());
            composer.setScreenAspect(w / h);
        }
    }

    // A context property, not qmlRegisterType: the cover page is loaded by URL
    // and cannot see ids declared in the app's root QML, so this is the only
    // clean way for the page and the cover to share one instance.
    view->rootContext()->setContextProperty(QStringLiteral("composer"), &composer);
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"),
                                            QStringLiteral(APP_VERSION));

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
