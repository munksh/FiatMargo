#include "ambiencecomposer.h"
#include "previewprovider.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QImageReader>
#include <QPainter>
#include <QStandardPaths>
#include <QUrl>
#include <QVector>

#include <cstring>

namespace {

/*
 * One output size, not a choice.
 *
 * Sailfish's own built-in ambiences are 2048 square, so this matches what the
 * platform already does. Offering 3072 beside it asked the user a question
 * they had no way to answer.
 */
const int kOutputSize = 2048;

/*
 * How much of the visible strip we refuse to trust, as a fraction of its
 * width. Also not a choice.
 *
 * The strip Sailfish keeps is exactly screenWidth/screenHeight of the square,
 * and measurement on the device confirms it. But ambience creation is not
 * WYSIWYG by the platform's own admission, so margo treats the strip as 4%
 * narrower than it really is. The photo therefore lands slightly INSIDE the
 * safe area rather than exactly on its edge: on the real screen you get a
 * little more of the photo than the preview promised, never less.
 *
 * 4% is about 2% off each side -- invisible, and it costs nothing worth
 * measuring. If a future device crops differently, this is the one number to
 * change.
 */
const qreal kSafety = 0.04;

// Longest side of the working copy used for the live preview. The preview is
// composed at 720 at most, and at full zoom the photo covers about three
// quarters of that, so anything above ~900 is pixels scaled down and thrown
// away on every single touch event. Saving always uses the full-resolution
// original, so this costs no output quality.
const int kWorkingMax = 900;

// Above this output size, compose() reaches for the full-resolution original
// instead of the working copy, and always scales smoothly.
const int kFullResThreshold = 1200;

const int kPreviewSettled = 720;
const int kPreviewLive = 420;

/*
 * Separable box blur with a running sum: cost is independent of the radius,
 * which matters because EdgeColour deliberately uses an enormous one.
 *
 * Three passes approximate a Gaussian closely enough that nothing in a
 * blurred photographic edge gives it away.
 *
 * Edges are clamped rather than wrapped or zeroed. Zeroing would darken the
 * outermost pixels of the square towards black, and those pixels are exactly
 * what ends up along the top and bottom of the lock screen.
 */
void boxBlurH(QImage &img, int radius)
{
    const int w = img.width();
    const int h = img.height();
    if (radius < 1 || w < 2) {
        return;
    }
    const int span = radius * 2 + 1;
    QVector<QRgb> row(w);

    for (int y = 0; y < h; ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(img.scanLine(y));
        std::memcpy(row.data(), line, size_t(w) * sizeof(QRgb));

        int a = 0, r = 0, g = 0, b = 0;
        for (int i = -radius; i <= radius; ++i) {
            const QRgb p = row.at(qBound(0, i, w - 1));
            a += qAlpha(p); r += qRed(p); g += qGreen(p); b += qBlue(p);
        }
        for (int x = 0; x < w; ++x) {
            line[x] = qRgba(r / span, g / span, b / span, a / span);
            const QRgb out = row.at(qBound(0, x - radius, w - 1));
            const QRgb in  = row.at(qBound(0, x + radius + 1, w - 1));
            a += qAlpha(in) - qAlpha(out);
            r += qRed(in)   - qRed(out);
            g += qGreen(in) - qGreen(out);
            b += qBlue(in)  - qBlue(out);
        }
    }
}

void boxBlurV(QImage &img, int radius)
{
    const int w = img.width();
    const int h = img.height();
    if (radius < 1 || h < 2) {
        return;
    }
    const int span = radius * 2 + 1;
    QVector<QRgb> col(h);

    for (int x = 0; x < w; ++x) {
        for (int y = 0; y < h; ++y) {
            col[y] = reinterpret_cast<QRgb *>(img.scanLine(y))[x];
        }

        int a = 0, r = 0, g = 0, b = 0;
        for (int i = -radius; i <= radius; ++i) {
            const QRgb p = col.at(qBound(0, i, h - 1));
            a += qAlpha(p); r += qRed(p); g += qGreen(p); b += qBlue(p);
        }
        for (int y = 0; y < h; ++y) {
            reinterpret_cast<QRgb *>(img.scanLine(y))[x] =
                    qRgba(r / span, g / span, b / span, a / span);
            const QRgb out = col.at(qBound(0, y - radius, h - 1));
            const QRgb in  = col.at(qBound(0, y + radius + 1, h - 1));
            a += qAlpha(in) - qAlpha(out);
            r += qRed(in)   - qRed(out);
            g += qGreen(in) - qGreen(out);
            b += qBlue(in)  - qBlue(out);
        }
    }
}

void blur(QImage &img, int radius)
{
    for (int pass = 0; pass < 3; ++pass) {
        boxBlurH(img, radius);
        boxBlurV(img, radius);
    }
}

} // namespace

AmbienceComposer::AmbienceComposer(PreviewProvider *provider, QObject *parent)
    : QObject(parent)
    , m_provider(provider)
    , m_screenAspect(0.45)
    , m_fillMode(EdgeSmear)
    , m_zoom(0.0)
    , m_offsetX(0.0)
    , m_offsetY(0.0)
    , m_revision(0)
    , m_tooSmall(false)
    , m_interactive(false)
    , m_busy(false)
    , m_savedCount(0)
{
    // Single-shot and restarted on every change, so a burst of touch events
    // collapses into one recomposition -- and because it always fires
    // eventually, the last position is never lost.
    m_previewTimer.setSingleShot(true);
    m_previewTimer.setInterval(33);
    connect(&m_previewTimer, &QTimer::timeout, this, &AmbienceComposer::refresh);
}

int AmbienceComposer::outputSize() const
{
    return kOutputSize;
}

void AmbienceComposer::schedulePreview()
{
    m_previewTimer.start();
}

void AmbienceComposer::beginInteraction()
{
    m_interactive = true;
}

void AmbienceComposer::endInteraction()
{
    if (!m_interactive) {
        return;
    }
    m_interactive = false;
    m_previewTimer.stop();
    refresh();          // immediately, and at full quality
}

qreal AmbienceComposer::effectiveAspect() const
{
    const qreal a = m_screenAspect * (1.0 - kSafety);
    return qBound(qreal(0.2), a, qreal(1.0));
}

bool AmbienceComposer::centred() const
{
    return qAbs(m_offsetX) < 0.001 && qAbs(m_offsetY) < 0.001;
}

void AmbienceComposer::setSourcePath(const QString &path)
{
    QString local = path;
    if (local.startsWith(QLatin1String("file:"))) {
        local = QUrl(local).toLocalFile();
    }
    if (local == m_sourcePath) {
        return;
    }

    m_sourcePath = local;
    m_sourceFull = QImage();
    m_source = QImage();

    if (!local.isEmpty()) {
        QImageReader reader(local);
        // Without this, every portrait photo taken on the phone arrives
        // sideways: the pixels are landscape and only the EXIF tag says
        // otherwise.
        reader.setAutoTransform(true);
        QImage loaded = reader.read();

        if (!loaded.isNull()) {
            m_sourceFull = loaded.convertToFormat(QImage::Format_ARGB32_Premultiplied);
            const int longest = qMax(m_sourceFull.width(), m_sourceFull.height());
            m_source = longest > kWorkingMax
                    ? m_sourceFull.scaled(kWorkingMax, kWorkingMax,
                                          Qt::KeepAspectRatio, Qt::SmoothTransformation)
                    : m_sourceFull;
        }
    }

    resetPlacement();
    emit sourceChanged();
    refresh();
}

void AmbienceComposer::setScreenAspect(qreal aspect)
{
    aspect = qBound(qreal(0.2), aspect, qreal(1.0));
    if (qFuzzyCompare(aspect, m_screenAspect)) {
        return;
    }
    m_screenAspect = aspect;
    emit settingsChanged();
    schedulePreview();
}

void AmbienceComposer::setFillMode(int mode)
{
    if (mode != EdgeColour && mode != EdgeSmear) {
        return;
    }
    if (mode == m_fillMode) {
        return;
    }
    m_fillMode = mode;
    emit settingsChanged();
    schedulePreview();
}

void AmbienceComposer::setZoom(qreal zoom)
{
    zoom = qBound(qreal(0.0), zoom, qreal(1.0));
    if (qFuzzyCompare(zoom, m_zoom)) {
        return;
    }
    m_zoom = zoom;
    emit settingsChanged();
    schedulePreview();
}

void AmbienceComposer::setOffsetX(qreal x)
{
    x = qBound(qreal(-0.5), x, qreal(0.5));
    if (qFuzzyCompare(x, m_offsetX)) {
        return;
    }
    m_offsetX = x;
    emit settingsChanged();
    schedulePreview();
}

void AmbienceComposer::setOffsetY(qreal y)
{
    y = qBound(qreal(-0.5), y, qreal(0.5));
    if (qFuzzyCompare(y, m_offsetY)) {
        return;
    }
    m_offsetY = y;
    emit settingsChanged();
    schedulePreview();
}

void AmbienceComposer::centre()
{
    if (centred()) {
        return;
    }
    m_offsetX = 0.0;
    m_offsetY = 0.0;
    emit settingsChanged();
    refresh();
}

void AmbienceComposer::resetPlacement()
{
    m_zoom = 0.0;
    m_offsetX = 0.0;
    m_offsetY = 0.0;
    emit settingsChanged();
}

void AmbienceComposer::clear()
{
    setSourcePath(QString());
}

QImage AmbienceComposer::compose(int size) const
{
    const bool fullRes = size > kFullResThreshold;
    const QImage &src = (fullRes && !m_sourceFull.isNull()) ? m_sourceFull : m_source;

    if (src.isNull() || size < 8) {
        return QImage();
    }

    // Fast scaling only while a finger is down, and never for the saved file.
    const Qt::TransformationMode mode = (m_interactive && !fullRes)
            ? Qt::FastTransformation
            : Qt::SmoothTransformation;

    const qreal aspect = effectiveAspect();
    const qreal stripW = size * aspect;
    const qreal stripH = size;

    // zoom 0 -> the whole photo fits inside the visible strip, nothing lost
    // zoom 1 -> the photo fills the strip completely, edges cropped
    const qreal containScale = qMin(stripW / src.width(), stripH / src.height());
    const qreal coverScale   = qMax(stripW / src.width(), stripH / src.height());
    const qreal scale = containScale + (coverScale - containScale) * m_zoom;

    const int pw = qMax(1, qRound(src.width() * scale));
    const int ph = qMax(1, qRound(src.height() * scale));
    const int px = qRound(size / 2.0 - pw / 2.0 + m_offsetX * size);
    const int py = qRound(size / 2.0 - ph / 2.0 + m_offsetY * size);

    const QImage placed = src.scaled(pw, ph, Qt::IgnoreAspectRatio, mode)
                             .convertToFormat(QImage::Format_ARGB32_Premultiplied);

    // ---- background ----------------------------------------------------
    // Built small, blurred there, then scaled up. It is going to be blurred
    // anyway, so computing it at full size buys nothing but seconds. The two
    // fill modes are the SAME construction with different blur radii: extend
    // the photo's edge pixels outward, then decide how far to let them melt.
    const int bgSize = qBound(128, size / 4, 512);
    const qreal k = qreal(bgSize) / qreal(size);

    const int spw = qMax(1, qRound(pw * k));
    const int sph = qMax(1, qRound(ph * k));
    const int spx = qRound(px * k);
    const int spy = qRound(py * k);

    const QImage smallPlaced = placed.scaled(spw, sph, Qt::IgnoreAspectRatio, mode)
                                     .convertToFormat(QImage::Format_ARGB32_Premultiplied);

    QImage background(bgSize, bgSize, QImage::Format_ARGB32_Premultiplied);
    for (int y = 0; y < bgSize; ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(background.scanLine(y));
        const int sy = qBound(0, y - spy, sph - 1);
        const QRgb *srcLine = reinterpret_cast<const QRgb *>(smallPlaced.constScanLine(sy));
        for (int x = 0; x < bgSize; ++x) {
            const int sx = qBound(0, x - spx, spw - 1);
            line[x] = srcLine[sx] | 0xff000000;   // force opaque
        }
    }

    const int radius = (m_fillMode == EdgeColour)
            ? qMax(1, bgSize / 5)
            : qMax(1, bgSize / 28);
    blur(background, radius);

    // ---- final -----------------------------------------------------------
    QImage out(size, size, QImage::Format_ARGB32_Premultiplied);
    QPainter painter(&out);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, mode == Qt::SmoothTransformation);
    painter.drawImage(QRect(0, 0, size, size), background);
    painter.drawImage(QPoint(px, py), placed);
    painter.end();

    return out.convertToFormat(QImage::Format_RGB32);
}

void AmbienceComposer::refresh()
{
    if (m_source.isNull()) {
        if (m_provider) {
            m_provider->setImage(QImage());
        }
        m_tooSmall = false;
        ++m_revision;
        emit previewChanged();
        return;
    }

    // Is the output going to be an upscale of the original? Work it out from
    // the FULL resolution source, since that is what save() will use.
    const QImage &full = m_sourceFull.isNull() ? m_source : m_sourceFull;
    const qreal aspect = effectiveAspect();
    const qreal stripW = kOutputSize * aspect;
    const qreal stripH = kOutputSize;
    const qreal containScale = qMin(stripW / full.width(), stripH / full.height());
    const qreal coverScale   = qMax(stripW / full.width(), stripH / full.height());
    const qreal scale = containScale + (coverScale - containScale) * m_zoom;

    m_tooSmall = scale > 1.1;

    const QImage preview = compose(m_interactive ? kPreviewLive : kPreviewSettled);
    if (m_provider) {
        m_provider->setImage(preview);
    }

    ++m_revision;
    emit previewChanged();
}

void AmbienceComposer::setBusy(bool busy)
{
    if (busy == m_busy) {
        return;
    }
    m_busy = busy;
    emit busyChanged();
}

bool AmbienceComposer::save()
{
    if (m_source.isNull()) {
        emit saveFailed(tr("No photo chosen"));
        return false;
    }

    setBusy(true);

    const QImage out = compose(kOutputSize);
    if (out.isNull()) {
        setBusy(false);
        emit saveFailed(tr("Could not build the image"));
        return false;
    }

    const QString picturesRoot =
            QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (picturesRoot.isEmpty()) {
        setBusy(false);
        emit saveFailed(tr("No Pictures folder"));
        return false;
    }

    QDir dir(picturesRoot + QLatin1String("/Ambiences"));
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        setBusy(false);
        emit saveFailed(tr("Could not create %1").arg(dir.path()));
        return false;
    }

    const QString base = QFileInfo(m_sourcePath).completeBaseName();
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-hhmmss"));
    const QString target = dir.filePath(QStringLiteral("margo-%1-%2.jpg").arg(base, stamp));

    if (!out.save(target, "JPEG", 95)) {
        setBusy(false);
        emit saveFailed(tr("Could not write %1").arg(target));
        return false;
    }

    m_lastSavedPath = target;
    ++m_savedCount;
    setBusy(false);
    emit lastSavedPathChanged();
    emit savedCountChanged();
    return true;
}
