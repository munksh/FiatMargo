#include "previewprovider.h"

#include <QMutexLocker>

PreviewProvider::PreviewProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage PreviewProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)

    QMutexLocker locker(&m_mutex);
    QImage image = m_image;
    locker.unlock();

    if (image.isNull()) {
        // Never return a null image -- QML logs a "Failed to get image from
        // provider" error and the Image element keeps its previous frame,
        // which looks like the preview refusing to clear.
        image = QImage(1, 1, QImage::Format_ARGB32_Premultiplied);
        image.fill(Qt::transparent);
    }

    if (size) {
        *size = image.size();
    }

    if (requestedSize.isValid()
            && !requestedSize.isEmpty()
            && requestedSize != image.size()) {
        return image.scaled(requestedSize,
                            Qt::KeepAspectRatio,
                            Qt::SmoothTransformation);
    }

    return image;
}

void PreviewProvider::setImage(const QImage &image)
{
    QMutexLocker locker(&m_mutex);
    m_image = image;
}
