/*
 * Copyright (C) 2026 eos
 *               2019 Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import org.asteroid.controls

import "../data/HealthStats.js" as Stats
import "../theme"

// One day from midnight to midnight, with the hour axis in the user's 12 or 24 hour format
// (health-fitness-13). Either a bar for each equal part of the day (bars: {lo, hi}, null: nothing
// logged then; lo 0 for steps per hour) or a line (points: {x: 0..1 of the day, y: value}, broken
// where more than maxGap of the day has no reading), over the clock hours 0, 6, 12 and 18:
// "12 AM, 6 AM, 12 PM, 6 PM" or "00, 06, 12, 18" (TimeFormat.hour). Stock: the heart rate line chart
// of today (aflu.java:1123-1127) and the steps bars.
Item {
    id: chart
    property date day: new Date()
    property var bars: []
    property var points: []
    // a gap of this much of the day without a reading breaks the line (30 minutes)
    property real maxGap: 30 / 1440
    property var ticks: [0, 50, 100]
    property real axisLo: ticks.length ? ticks[0] : 0
    property real axisHi: ticks.length ? ticks[ticks.length - 1] : 1
    // the bar drawn brightest (the latest one), -1 none
    property int highlight: -1
    // a dashed line at this value (the hourly step goal), -1 none
    property real goal: -1
    property color barColor: HealthPalette.fitness.main
    property color lineColor: barColor
    property bool showLabels: true
    // round ends past lo and hi (a range); false: the bar stands on lo
    property bool capped: true
    property string labelRole: "bodyExtraSmall"
    property real labelSize: Theme.type[labelRole].pixelSize
    // the hours of the axis labels
    property var labelHours: [0, 6, 12, 18]

    readonly property real gutter: showLabels ? Theme.dp(20) : 0
    readonly property real plotWidth: width - gutter
    readonly property real plotHeight: height - (showLabels ? labelSize * 2.5 : 0)

    function yOf(v) {
        return plotHeight * (1 - (v - axisLo) / Math.max(1e-6, axisHi - axisLo))
    }

    // the label of an hour of this day
    function hourText(h) {
        return TimeFormat.hour(new Date(day.getFullYear(), day.getMonth(), day.getDate(), h))
    }

    onPointsChanged: line.requestPaint()
    onAxisLoChanged: line.requestPaint()
    onAxisHiChanged: line.requestPaint()
    onWidthChanged: line.requestPaint()
    onHeightChanged: line.requestPaint()

    // horizontal grid lines and their values, left of the plot
    Repeater {
        model: chart.ticks
        delegate: Item {
            y: chart.yOf(modelData)
            width: chart.width
            Rectangle {
                x: chart.gutter
                width: chart.plotWidth
                height: Theme.dp(1)
                color: HealthPalette.track
            }
            Label {
                visible: chart.showLabels
                anchors.right: parent.left
                anchors.rightMargin: -chart.gutter + Theme.dp(2)
                anchors.verticalCenter: parent.top
                role: chart.labelRole
                color: HealthPalette.label
                text: Stats.shortNumber(modelData)
            }
        }
    }

    // the hourly goal
    Row {
        visible: chart.goal > 0 && chart.goal <= chart.axisHi
        x: chart.gutter
        y: chart.yOf(chart.goal)
        spacing: Theme.dp(3)
        Repeater {
            model: Math.max(0, Math.floor(chart.plotWidth / Theme.dp(8)))
            Rectangle { width: Theme.dp(5); height: Theme.dp(1); color: chart.barColor; opacity: 0.8 }
        }
    }

    Repeater {
        model: chart.bars.length
        delegate: Rectangle {
            readonly property var bar: chart.bars[index]
            readonly property real slot: chart.plotWidth / chart.bars.length
            visible: bar !== null && bar !== undefined
            width: Math.max(Theme.dp(1), slot * 0.6)
            x: chart.gutter + slot * index + (slot - width) / 2
            readonly property real cap: chart.capped ? width / 2 : 0
            y: visible ? Math.min(chart.yOf(bar.hi) - cap, chart.yOf(bar.lo) + cap - width) : 0
            height: visible ? Math.max(width, chart.yOf(bar.lo) - chart.yOf(bar.hi) + 2 * cap) : 0
            radius: width / 2
            color: chart.barColor
            opacity: index === chart.highlight ? 1 : 0.75
        }
    }

    // the line: a stroke of 2 dp, round joins, one piece for every run of readings
    Canvas {
        id: line
        x: chart.gutter
        width: chart.plotWidth
        height: chart.plotHeight
        visible: chart.points.length > 0
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var pts = chart.points
            if (!pts || pts.length === 0)
                return
            ctx.strokeStyle = chart.lineColor
            ctx.fillStyle = chart.lineColor
            ctx.lineWidth = Theme.dp(2)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            var run = 0
            var prev = -1
            var lastX = 0
            var lastY = 0
            for (var i = 0; i < pts.length; i++) {
                var px = pts[i].x * width
                var py = chart.yOf(pts[i].y)
                if (run > 0 && pts[i].x - prev > chart.maxGap) {
                    // a lone reading is a dot (a zero-length line with round caps)
                    if (run === 1)
                        ctx.lineTo(lastX + 0.01, lastY)
                    ctx.stroke()
                    run = 0
                }
                if (run === 0) {
                    ctx.beginPath()
                    ctx.moveTo(px, py)
                } else {
                    ctx.lineTo(px, py)
                }
                run++
                prev = pts[i].x
                lastX = px
                lastY = py
            }
            if (run === 1)
                ctx.lineTo(lastX + 0.01, lastY)
            if (run > 0)
                ctx.stroke()
        }
    }

    // the time axis
    Repeater {
        model: chart.showLabels ? chart.labelHours : []
        delegate: Item {
            x: chart.gutter + chart.plotWidth * Stats.hourFraction(chart.day, modelData)
            y: chart.plotHeight
            Rectangle {
                width: Theme.dp(1)
                height: chart.labelSize * 0.35
                anchors.horizontalCenter: parent.left
                color: HealthPalette.label
                opacity: 0.5
            }
            Label {
                // each label is centred on its hour
                x: -implicitWidth / 2
                y: chart.labelSize * 0.8
                role: chart.labelRole
                color: HealthPalette.label
                text: chart.hourText(modelData)
            }
        }
    }
}
