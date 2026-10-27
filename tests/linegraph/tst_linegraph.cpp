/*
 * Host test of LineGraph_p (src/cpp/lineGraph_p.cpp), the heart rate / steps line graph of asteroid-health.
 * eos change under test: "LineGraph: an empty range clears the graph, quietly" (an empty range no longer keeps
 * showing the range loaded before). Also the scaling of loadGraphData() and what paint() draws.
 * The graph is painted into a QImage; no window is needed.
 */
#include <QtTest>
#include <QImage>
#include <QPainter>
#include <QSignalSpy>

#include "lineGraph_p.h"

namespace {
QVariant points(const QList<QPointF> &pts)
{
    QVariantList l;
    for (const QPointF &p : pts)
        l << QVariant(p);
    return l;
}

/* number of pixels the graph paints on a transparent 100 x 50 image */
int painted(LineGraph_p &g, QImage *out = nullptr)
{
    QImage img(100, 50, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    {
        QPainter p(&img);
        g.paint(&p);
    }
    int n = 0;
    for (int y = 0; y < img.height(); y++)
        for (int x = 0; x < img.width(); x++)
            n += qAlpha(img.pixel(x, y)) != 0;
    if (out)
        *out = img;
    return n;
}

/* the row of the topmost and bottommost painted pixel in column x, -1 if none */
QPair<int, int> column(const QImage &img, int x)
{
    int top = -1, bottom = -1;
    for (int y = 0; y < img.height(); y++) {
        if (qAlpha(img.pixel(x, y))) {
            if (top < 0)
                top = y;
            bottom = y;
        }
    }
    return { top, bottom };
}
}

class TestLineGraph : public QObject
{
    Q_OBJECT

private slots:
    void emptyRangeClearsTheGraph()
    {
        LineGraph_p g;
        g.setSize(QSizeF(100, 50));
        g.setLineWidth(2);
        g.setRelative(true);
        g.loadGraphData(points({ { 1000, 60 }, { 1600, 80 }, { 2200, 70 } }));
        QVERIFY(painted(g) > 0);
        QSignalSpy done(&g, &LineGraph_p::loadingDone);
        g.loadGraphData(QVariantList());
        QCOMPARE(painted(g), 0);   /* before the eos fix it still drew the previous range */
        QCOMPARE(done.count(), 0); /* nothing loaded: no loadingDone */
        /* and a non-list is no data either */
        g.loadGraphData(QVariant(42));
        QCOMPARE(painted(g), 0);
    }

    void singlePointDrawsNothing()
    {
        LineGraph_p g;
        g.setSize(QSizeF(100, 50));
        g.setLineWidth(2);
        g.loadGraphData(points({ { 1000, 60 } }));
        QCOMPARE(painted(g), 0);
    }

    void rangeAndTimes()
    {
        LineGraph_p g;
        QSignalSpy done(&g, &LineGraph_p::loadingDone);
        g.loadGraphData(points({ { 1761000000, 72 }, { 1761000600, 55 }, { 1761001200, 101 }, { 1761001800, 64 } }));
        QCOMPARE(done.count(), 1);
        QCOMPARE(g.getMinValue(), 55);
        QCOMPARE(g.getMaxValue(), 101);
        QCOMPARE(g.getMinTime(), QDateTime::fromSecsSinceEpoch(1761000000));
        QCOMPARE(g.getMaxTime(), QDateTime::fromSecsSinceEpoch(1761001800));
        /* a new range replaces the old one completely */
        g.loadGraphData(points({ { 1761100000, 90 }, { 1761100060, 91 } }));
        QCOMPARE(g.getMinValue(), 90);
        QCOMPARE(g.getMaxValue(), 91);
        QCOMPARE(done.count(), 2);
    }

    void relativeScalesToTheRangeAbsoluteFromZero()
    {
        /* a rising line 50 -> 100: relative fills the height, absolute starts at half height */
        LineGraph_p rel;
        rel.setSize(QSizeF(100, 50));
        rel.setLineWidth(2);
        rel.setRelative(true);
        rel.loadGraphData(points({ { 0, 50 }, { 100, 100 } }));
        QImage ri;
        QVERIFY(painted(rel, &ri) > 0);
        const auto rLeft = column(ri, 2);
        QVERIFY2(rLeft.second >= 45, "relative: the minimum is at the bottom");
        QCOMPARE(rel.getMinValue(), 50);

        LineGraph_p abs;
        abs.setSize(QSizeF(100, 50));
        abs.setLineWidth(2);
        abs.setRelative(false);
        abs.loadGraphData(points({ { 0, 50 }, { 100, 100 } }));
        QImage ai;
        QVERIFY(painted(abs, &ai) > 0);
        const auto aLeft = column(ai, 2);
        QVERIFY2(aLeft.first > 15 && aLeft.second < 35, "absolute: 50 of 0..100 is about half way");
        /* the right end is the maximum, at the top, in both modes */
        QVERIFY(column(ri, 97).first <= 4);
        QVERIFY(column(ai, 97).first <= 4);
        /* note: absolute painting resets the reported minimum to 0 */
        QCOMPARE(abs.getMinValue(), 0);
        QVERIFY(abs.relative() == false && rel.relative() == true);
    }

    void flatLineIsDrawn()
    {
        /* every reading the same (a steady heart rate): valueDelta is 0 and paint() divides by it */
        LineGraph_p g;
        g.setSize(QSizeF(100, 50));
        g.setLineWidth(2);
        g.setRelative(true);
        g.loadGraphData(points({ { 0, 70 }, { 100, 70 }, { 200, 70 } }));
        QEXPECT_FAIL("", "bug: paint() divides by maxValue - minValue == 0 (all points NaN, nothing drawn); "
                         "patches/asteroid-health/0001", Continue);
        QVERIFY(painted(g) > 0);
    }

    void sameTimestampIsDrawn()
    {
        /* two readings in the same second: timeDelta is 0 */
        LineGraph_p g;
        g.setSize(QSizeF(100, 50));
        g.setLineWidth(2);
        g.setRelative(true);
        g.loadGraphData(points({ { 500, 60 }, { 500, 80 } }));
        QEXPECT_FAIL("", "bug: paint() divides by maxTime - minTime == 0; patches/asteroid-health/0001", Continue);
        QVERIFY(painted(g) > 0);
    }

    void colourAndWidth()
    {
        LineGraph_p g;
        QCOMPARE(g.lineColor(), QColor(255, 255, 255));
        g.setLineColor(QColor(10, 200, 30));
        QCOMPARE(g.lineColor(), QColor(10, 200, 30));
        g.setLineWidth(3.5f);
        QCOMPARE(g.lineWidth(), 3.5f);
        g.setSize(QSizeF(100, 50));
        g.setRelative(true);
        g.loadGraphData(points({ { 0, 1 }, { 10, 2 } }));
        QImage img;
        QVERIFY(painted(g, &img) > 0);
        bool green = false;
        for (int x = 0; x < img.width() && !green; x++)
            for (int y = 0; y < img.height() && !green; y++) {
                const QRgb c = img.pixel(x, y);
                green = qAlpha(c) == 255 && qGreen(c) > 150 && qRed(c) < 60;
            }
        QVERIFY(green);
    }
};

QTEST_MAIN(TestLineGraph)
#include "tst_linegraph.moc"
