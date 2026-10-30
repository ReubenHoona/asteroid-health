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

// A bar a day: days is a list of {label, hasData, lo, hi, mark} (mark: a
// dot at that value, such as the resting heart rate; -1 none). A day without
// data keeps its place with a dash. Tapping a day: dayClicked(index).
Item {
    id: chart
    property var days: []
    property var ticks: [0, 50, 100]
    property real axisLo: ticks.length ? ticks[0] : 0
    property real axisHi: ticks.length ? ticks[ticks.length - 1] : 1
    property int selected: -1
    // a dashed line at this value (the step goal), -1 none
    property real goal: -1
    property bool capped: true
    property color markColor: "#FF5A6A"
    property real labelSize: Dims.l(4.5)
    signal dayClicked(int index)

    readonly property real gutter: Dims.l(9)
    readonly property real plotWidth: width - gutter
    readonly property real plotHeight: height - labelSize * 1.8
    readonly property real slot: plotWidth / Math.max(1, days.length)

    function yOf(v) {
        return plotHeight * (1 - (v - axisLo) / Math.max(1e-6, axisHi - axisLo))
    }

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
                anchors.right: parent.left
                anchors.rightMargin: -chart.gutter + Dims.l(1.5)
                anchors.verticalCenter: parent.top
                font.pixelSize: chart.labelSize
                opacity: 0.7
                text: Stats.shortNumber(modelData)
            }
        }
    }

    Row {
        visible: chart.goal > 0 && chart.goal <= chart.axisHi
        x: chart.gutter
        y: chart.yOf(chart.goal)
        spacing: Dims.l(1)
        Repeater {
            model: Math.max(0, Math.floor(chart.plotWidth / Dims.l(3)))
            Rectangle { width: Dims.l(2); height: 2; color: chart.markColor; opacity: 0.8 }
        }
    }

    Repeater {
        model: chart.days.length
        delegate: MouseArea {
            readonly property var d: chart.days[index]
            x: chart.gutter + chart.slot * index
            width: chart.slot
            height: chart.height
            onClicked: chart.dayClicked(index)

            Rectangle {
                id: bar
                visible: d.hasData
                width: Math.min(chart.slot * 0.55, Dims.l(5))
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real cap: chart.capped ? width / 2 : 0
                y: visible ? Math.min(chart.yOf(d.hi) - cap, chart.yOf(d.lo) + cap - width) : 0
                height: visible ? Math.max(width, chart.yOf(d.lo) - chart.yOf(d.hi) + 2 * cap) : 0
                radius: width / 2
                color: "#FFFFFF"
                opacity: index === chart.selected ? 1 : 0.55
            }
            Rectangle {
                visible: d.hasData && d.mark >= 0
                width: bar.width * 0.7
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
                font.pixelSize: chart.labelSize * 1.2
                opacity: 0.5
                text: "–"
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                y: chart.plotHeight + chart.labelSize * 0.4
                font.pixelSize: chart.labelSize
                font.bold: index === chart.selected
                opacity: index === chart.selected ? 1 : 0.7
                text: d.label
            }
        }
    }
}
