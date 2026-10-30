/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
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

// One day from midnight to midnight: a bar for each equal part of the day,
// from its low to its high ({lo, hi}; null: nothing logged then), over the
// local clock hours 0, 6, 12 and 18. The heart rate range chart of the
// stock Fitbit day view; with lo 0 the steps per hour.
Item {
    id: chart
    property date day: new Date()
    property var bars: []
    property var ticks: [0, 50, 100]
    property real axisLo: ticks.length ? ticks[0] : 0
    property real axisHi: ticks.length ? ticks[ticks.length - 1] : 1
    // the bar drawn brightest (the latest one), -1 none
    property int highlight: -1
    property color barColor: "#FFFFFF"
    property bool showLabels: true
    // round ends past lo and hi (a range); false: the bar stands on lo
    property bool capped: true
    property real labelSize: Dims.l(4.5)

    readonly property real gutter: showLabels ? Dims.l(9) : 0
    readonly property real plotWidth: width - gutter
    readonly property real plotHeight: height - (showLabels ? labelSize * 1.6 : 0)

    function yOf(v) {
        return plotHeight * (1 - (v - axisLo) / Math.max(1e-6, axisHi - axisLo))
    }

    // horizontal grid lines and their values, inside the plot on the left
    Repeater {
        model: chart.ticks
        delegate: Item {
            y: chart.yOf(modelData)
            width: chart.width
            Rectangle {
                x: chart.gutter
                width: chart.plotWidth
                height: 1
                color: "#FFFFFF"
                opacity: 0.18
            }
            Label {
                visible: chart.showLabels
                anchors.right: parent.left
                anchors.rightMargin: -chart.gutter + Dims.l(1.5)
                anchors.verticalCenter: parent.top
                font.pixelSize: chart.labelSize
                opacity: 0.7
                text: Stats.shortNumber(modelData)
            }
        }
    }

    Repeater {
        model: chart.bars.length
        delegate: Rectangle {
            readonly property var bar: chart.bars[index]
            readonly property real slot: chart.plotWidth / chart.bars.length
            visible: bar !== null && bar !== undefined
            width: Math.max(2, slot * 0.6)
            x: chart.gutter + slot * index + (slot - width) / 2
            readonly property real cap: chart.capped ? width / 2 : 0
            y: visible ? Math.min(chart.yOf(bar.hi) - cap, chart.yOf(bar.lo) + cap - width) : 0
            height: visible ? Math.max(width, chart.yOf(bar.lo) - chart.yOf(bar.hi) + 2 * cap) : 0
            radius: width / 2
            color: chart.barColor
            opacity: index === chart.highlight ? 1 : 0.75
        }
    }

    // the time axis
    Repeater {
        model: chart.showLabels ? [0, 6, 12, 18] : []
        delegate: Item {
            x: chart.gutter + chart.plotWidth * Stats.hourFraction(chart.day, modelData)
            y: chart.plotHeight
            Rectangle {
                width: 1
                height: chart.labelSize * 0.35
                anchors.horizontalCenter: parent.left
                color: "#FFFFFF"
                opacity: 0.5
            }
            Label {
                anchors.horizontalCenter: parent.left
                y: chart.labelSize * 0.4
                font.pixelSize: chart.labelSize
                opacity: 0.7
                text: modelData
            }
        }
    }
}
