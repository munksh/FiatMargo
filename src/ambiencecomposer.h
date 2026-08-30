#ifndef AMBIENCECOMPOSER_H
#define AMBIENCECOMPOSER_H

#include <QObject>
#include <QImage>
#include <QString>
#include <QTimer>

class PreviewProvider;

/*
 * The whole of fiat margo's actual work.
 *
 * Sailfish turns a photo into an ambience in two crops:
 *
 *   1. the photo is forced into a SQUARE
 *   2. that square is stretched to the height of the screen and the left and
 *      right edges are sliced off to match the screen's width
 *
 * So the part of the square that survives is a centred vertical strip, full
 * height, of width  size * (screenWidth / screenHeight).  Everything outside
 * that strip is thrown away.
 *
 * This class places the whole, uncropped photo inside that strip and fills
 * everything around it with colour taken from the photo's own edges. Note
 * that the strip is FULL HEIGHT, so for a normal 3:4 photo the fill above and
 * below the picture is *visible on the phone* -- it is not discarded like the
 * left and right fill. That is why the fill has to look like it belongs.
 */
class AmbienceComposer : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString sourcePath READ sourcePath WRITE setSourcePath NOTIFY sourceChanged)
    Q_PROPERTY(bool hasSource READ hasSource NOTIFY sourceChanged)
    Q_PROPERTY(int sourceWidth READ sourceWidth NOTIFY sourceChanged)
    Q_PROPERTY(int sourceHeight READ sourceHeight NOTIFY sourceChanged)

    Q_PROPERTY(qreal screenAspect READ screenAspect WRITE setScreenAspect NOTIFY settingsChanged)
    Q_PROPERTY(int fillMode READ fillMode WRITE setFillMode NOTIFY settingsChanged)

    Q_PROPERTY(qreal zoom READ zoom WRITE setZoom NOTIFY settingsChanged)
    Q_PROPERTY(qreal offsetX READ offsetX WRITE setOffsetX NOTIFY settingsChanged)
    Q_PROPERTY(qreal offsetY READ offsetY WRITE setOffsetY NOTIFY settingsChanged)
    Q_PROPERTY(bool centred READ centred NOTIFY settingsChanged)

    // The fraction of the square that survives Sailfish's second crop.
    // A property, not an invokable: QML needs it to re-evaluate when the
    // screen ratio changes.
    Q_PROPERTY(qreal effectiveAspect READ effectiveAspect NOTIFY settingsChanged)

    // One fixed value. See kOutputSize.
    Q_PROPERTY(int outputSize READ outputSize CONSTANT)

    Q_PROPERTY(int revision READ revision NOTIFY previewChanged)
    Q_PROPERTY(bool tooSmall READ tooSmall NOTIFY previewChanged)

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString lastSavedPath READ lastSavedPath NOTIFY lastSavedPathChanged)
    Q_PROPERTY(int savedCount READ savedCount NOTIFY savedCountChanged)

public:
    // Kept as plain ints rather than a registered enum: the object reaches QML
    // as a context property, and a context property carries no type namespace,
    // so QML could not say AmbienceComposer.EdgeSmear anyway. MainPage.qml
    // declares matching readonly properties.
    enum FillMode {
        EdgeColour = 0,   // heavy blur -- soft fields of the edge colours
        EdgeSmear  = 1    // light blur -- the edge continues outward, row by row
    };

    explicit AmbienceComposer(PreviewProvider *provider, QObject *parent = nullptr);

    QString sourcePath() const { return m_sourcePath; }
    void setSourcePath(const QString &path);
    bool hasSource() const { return !m_source.isNull(); }
    int sourceWidth() const { return m_source.isNull() ? 0 : m_sourceFull.width(); }
    int sourceHeight() const { return m_source.isNull() ? 0 : m_sourceFull.height(); }

    qreal screenAspect() const { return m_screenAspect; }
    void setScreenAspect(qreal aspect);

    int outputSize() const;

    int fillMode() const { return m_fillMode; }
    void setFillMode(int mode);

    qreal zoom() const { return m_zoom; }
    void setZoom(qreal zoom);

    qreal offsetX() const { return m_offsetX; }
    void setOffsetX(qreal x);

    qreal offsetY() const { return m_offsetY; }
    void setOffsetY(qreal y);

    bool centred() const;

    int revision() const { return m_revision; }
    bool tooSmall() const { return m_tooSmall; }

    bool busy() const { return m_busy; }
    QString lastSavedPath() const { return m_lastSavedPath; }
    int savedCount() const { return m_savedCount; }

    qreal effectiveAspect() const;

    /*
     * Interaction bracketing.
     *
     * While a finger is down the preview is rebuilt smaller and with fast
     * scaling, because a drag that has to wait for a full-quality
     * recomposition between touch events feels like the app has stopped
     * listening. endInteraction() puts the good one back immediately.
     */
    Q_INVOKABLE void beginInteraction();
    Q_INVOKABLE void endInteraction();

    Q_INVOKABLE void centre();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void resetPlacement();
    Q_INVOKABLE bool save();
    Q_INVOKABLE void clear();

signals:
    void sourceChanged();
    void settingsChanged();
    void previewChanged();
    void busyChanged();
    void lastSavedPathChanged();
    void savedCountChanged();
    void saveFailed(const QString &reason);

private:
    QImage compose(int size) const;
    void schedulePreview();
    void setBusy(bool busy);

    PreviewProvider *m_provider;

    QString m_sourcePath;
    QImage m_source;          // EXIF-corrected, downscaled working copy
    QImage m_sourceFull;      // EXIF-corrected, full resolution

    qreal m_screenAspect;
    int m_fillMode;

    qreal m_zoom;
    qreal m_offsetX;
    qreal m_offsetY;

    int m_revision;
    bool m_tooSmall;
    bool m_interactive;

    bool m_busy;
    QString m_lastSavedPath;
    int m_savedCount;

    // Coalesces preview rebuilds. Dragging fires a setter per touch event, and
    // each one used to recompose immediately on the GUI thread -- so the drag
    // competed with its own preview for the main loop.
    QTimer m_previewTimer;
};

#endif // AMBIENCECOMPOSER_H
