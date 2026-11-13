/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
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

// The last seven days, a bar a day (days: {label, hasData, lo, hi, mark}; mark: a dot at that value,
// such as the resting heart rate; -1 none), or with `line` a line through the dots of the marks
// (the resting heart rate of the week, stock's "Resting heart rate line chart"). A day without data keeps
// its place with a dash. With `stacks` a bar is the days' minutes in several colours (the heart rate zones):
// stacks is a list of [{value, color}] per day, from the bottom. The chart is not interactive: stock's
// detail pages show the week and nothing older (health-fitness-25).
Item {
    id: chart
    property var days: []
    property var stacks: []
    property var ticks: [0, 50, 100]
    property real axisLo: ticks.length ? ticks[0] : 0
    property real axisHi: ticks.length ? ticks[ticks.length - 1] : 1
    // today's bar (the last) is drawn brightest, -1 none
    property int selected: -1
    // a dashed line at this value (the step goal), -1 none
    property real goal: -1
    property bool capped: true
    property bool line: false
    property color barColor: HealthPalette.fitness.main
    property color markColor: HealthPalette.health.main
    property string labelRole: "bodyExtraSmall"
    property real labelSize: Theme.type[labelRole].pixelSize

    readonly property real gutter: Theme.dp(20)
    readonly property real plotWidth: width - gutter
    readonly property real plotHeight: height - labelSize * 2.5
    readonly property real slot: plotWidth / Math.max(1, days.length)

    function yOf(v) {
        return plotHeight * (1 - (v - axisLo) / Math.max(1e-6, axisHi - axisLo))
    }

    onDaysChanged: connector.requestPaint()
    onAxisLoChanged: connector.requestPaint()
    onAxisHiChanged: connector.requestPaint()
    onWidthChanged: connector.requestPaint()

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
                anchors.right: parent.left
                anchors.rightMargin: -chart.gutter + Theme.dp(2)
                anchors.verticalCenter: parent.top
                role: chart.labelRole
                color: HealthPalette.label
                text: Stats.shortNumber(modelData)
            }
        }
    }

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

    // the line of the marks, between the days that have one
    Canvas {
        id: connector
        x: chart.gutter
        width: chart.plotWidth
        height: chart.plotHeight
        visible: chart.line
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (!chart.line)
                return
            ctx.strokeStyle = chart.markColor
            ctx.lineWidth = Theme.dp(2)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            var open = false
            for (var i = 0; i < chart.days.length; i++) {
                var d = chart.days[i]
                if (!d.hasData || d.mark < 0) {
                    if (open)
                        ctx.stroke()
                    open = false
                    continue
                }
                var x = chart.slot * (i + 0.5)
                var y = chart.yOf(d.mark)
                if (!open) {
                    ctx.beginPath()
                    ctx.moveTo(x, y)
                    open = true
                } else {
                    ctx.lineTo(x, y)
                }
            }
            if (open)
                ctx.stroke()
        }
    }

    Repeater {
        model: chart.days.length
        delegate: Item {
            readonly property var d: chart.days[index]
            readonly property var stack: chart.stacks[index] || []
            x: chart.gutter + chart.slot * index
            width: chart.slot
            height: chart.height

            Rectangle {
                id: bar
                visible: !chart.line && d.hasData && stack.length === 0
                width: Math.min(chart.slot * 0.55, Theme.dp(11))
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real cap: chart.capped ? width / 2 : 0
                y: visible ? Math.min(chart.yOf(d.hi) - cap, chart.yOf(d.lo) + cap - width) : 0
                height: visible ? Math.max(width, chart.yOf(d.lo) - chart.yOf(d.hi) + 2 * cap) : 0
                radius: width / 2
                color: chart.barColor
                opacity: index === chart.selected ? 1 : 0.6
            }
            // stacked minutes, one colour each
            Repeater {
                model: stack.length
                delegate: Rectangle {
                    readonly property real below: {
                        var s = 0
                        for (var k = 0; k < index; k++)
                            s += stack[k].value
                        return s
                    }
                    visible: stack[index].value > 0
                    width: Math.min(chart.slot * 0.55, Theme.dp(11))
                    x: (chart.slot - width) / 2
                    y: chart.yOf(below + stack[index].value)
                    height: Math.max(0, chart.yOf(below) - chart.yOf(below + stack[index].value))
                    color: stack[index].color
                }
            }
            Rectangle {
                visible: d.hasData && d.mark >= 0
                width: chart.line ? Theme.dp(8) : bar.width * 0.7
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: chart.yOf(d.mark) - height / 2
                color: chart.markColor
            }
            Label {
                // no data that day: its place stays, with a dash
                visible: !d.hasData
                anchors.horizontalCenter: parent.horizontalCenter
                y: chart.plotHeight - height
                role: chart.labelRole
                color: HealthPalette.label
                text: "-"
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                y: chart.plotHeight + chart.labelSize * 0.8
                role: chart.labelRole
                color: index === chart.selected ? Theme.color.onBackground : HealthPalette.label
                text: d.label
            }
        }
    }
}
