#ifndef PREVIEWPROVIDER_H
#define PREVIEWPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>
#include <QMutex>

/*
 * Hands the composed preview to QML without ever touching the filesystem.
 *
 * The QML engine takes ownership of an image provider once it is added, so
 * this is created with new and never deleted by us. AmbienceComposer keeps a
 * bare pointer to it and only ever calls setImage().
 */
class PreviewProvider : public QQuickImageProvider
{
public:
    PreviewProvider();

    // Called from QML's render thread.
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

    // Called from the GUI thread.
    void setImage(const QImage &image);

private:
    QImage m_image;
    QMutex m_mutex;
};

#endif // PREVIEWPROVIDER_H
