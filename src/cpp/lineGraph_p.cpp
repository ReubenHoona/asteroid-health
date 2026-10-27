/*
 * Copyright (C) 2023 Arseniy Movshev <dodoradio@outlook.com>
 *               2017 Florent Revest <revestflo@gmail.com>
 * All rights reserved.
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the author nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "lineGraph_p.h"

#include <QPainter>
#include <QDate>
#include <QFile>
#include <QVector>
#include <QSettings>
#include <QStandardPaths>
#include <QPointF>

LineGraph_p::LineGraph_p()
{
    setFlag(ItemHasContents, true);
    setAntialiasing(true);
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
}

void LineGraph_p::paint(QPainter *painter)
{
    if (m_filedata.count() < 2) // nothing (or a single point) to draw
        return;
    int j = m_filedata.count();
    QPointF points[j];
    if (!graphRelative) {
        minValue = 0;
    }
    float valueDelta = maxValue - minValue;
    float timeDelta = maxTime - minTime;
    float calculatedValue = 0;
    float calculatedTimeSeconds = 0;
    for(int i = 0; i < j; i++) {
        // a range of equal values or of one instant goes in the middle (no division by 0)
        calculatedTimeSeconds = timeDelta > 0 ? (m_filedata[i].x() - minTime)/timeDelta : 0.5f;
        calculatedValue = valueDelta > 0 ? 1 - (m_filedata[i].y() - minValue)/valueDelta : 0.5f;
        points[i] = QPointF(m_lineWidth + calculatedTimeSeconds*(width()-2*m_lineWidth), m_lineWidth + calculatedValue*(height()-2*m_lineWidth)); //these +2 -1 are here to make sure that the graph fits within the drawn area, as it will be clipped by qt if it doesn't.
    }
    QPen pen;
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);
    pen.setWidthF(m_lineWidth);
    pen.setColor(m_color);
    painter->setRenderHints(QPainter::Antialiasing);
    painter->setPen(pen);
    painter->drawPolyline(points,j);
}

void LineGraph_p::loadGraphData(QVariant fileDataInput) {
    QList<QVariant> fileDataAsList = fileDataInput.toList();
    if (fileDataAsList.count() < 1) {
        // nothing logged in this range (not an error): do not keep showing
        // the range loaded before
        m_filedata.clear();
        update();
        return;
    }
    int j = fileDataAsList.count();
    minTime = fileDataAsList[0].toPointF().x();
    maxTime = fileDataAsList[j-1].toPointF().x();
    minValue = fileDataAsList[0].toPointF().y();
    maxValue = minValue;
    m_filedata.clear();
    for(int i = 0; i < j; i++) {
        m_filedata.append(fileDataAsList[i].toPointF());
        if (minValue > m_filedata[i].y()) minValue = m_filedata[i].y();
        if (maxValue < m_filedata[i].y()) maxValue = m_filedata[i].y();
    }
    emit loadingDone();
    update();
}

void LineGraph_p::setLineColor(QColor color) {
    m_color = color;
    update();
}

QColor LineGraph_p::lineColor() {
    return m_color;
}

void LineGraph_p::setLineWidth(float width) {
    m_lineWidth = width;
    update();
}

float LineGraph_p::lineWidth() {
    return m_lineWidth;
}

int LineGraph_p::getMaxValue() {
    return maxValue;
}

int LineGraph_p::getMinValue() {
    return minValue;
}

QDateTime LineGraph_p::getMaxTime() {
    return QDateTime::fromSecsSinceEpoch(maxTime);
}

QDateTime LineGraph_p::getMinTime() {
    return QDateTime::fromSecsSinceEpoch(minTime);
}

bool LineGraph_p::relative() {
    return graphRelative;
}

void LineGraph_p::setRelative(bool newRelative) {
    graphRelative = newRelative;
}
