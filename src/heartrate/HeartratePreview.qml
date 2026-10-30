/*
 * Copyright (C) 2023 Arseniy Movshev <dodoradio@outlook.com>
 *               2026 Reuben Horner <reubarb.scons@gmail.com>
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

import org.asteroid.sensorlogd

import "../graphs"
import "../data/HealthStats.js" as Stats

// Today's heart rate, as the stock heart rate tile: the latest reading,
// when it was taken and today's range bars
MouseArea {
    id: preview
    implicitHeight: contentColumn.implicitHeight
    property var day: Stats.heartRateDay([], new Date(), 48)

    function reload() {
        var d = Stats.addDays(new Date(), 0)
        day = Stats.heartRateDay(hrDataLoader.getDataForDate(d), d, 48)
    }

    HrDataLoader {
        id: hrDataLoader
        onDataChanged: preview.reload()
    }
    Component.onCompleted: reload()

    Column {
        id: contentColumn
        anchors.fill: parent
        Label {
            anchors {
                left: parent.left
                margins: app.width*0.1
            }
            //% "Heartrate"
            text: qsTrId("id-heartrate")
        }

        Item { width: parent.width; height: parent.width*0.05}

        Label {
            width: parent.width*0.8
            anchors.horizontalCenter: parent.horizontalCenter
            visible: preview.day.count === 0
            //% "No heart rate logged today"
            text: qsTrId("id-no-heartrate-today")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Dims.l(2)
            visible: preview.day.count > 0
            Icon {
                name: "ios-heart"
                color: "#FF5A6A"
                width: Dims.l(7)
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                id: value
                text: preview.day.latest
                font.pixelSize: Dims.l(11)
            }
            Label {
                anchors.baseline: value.baseline
                text: qsTrId("id-bpm") + "  " + new Date(preview.day.latestTime * 1000).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                font.pixelSize: Dims.l(5)
                opacity: 0.8
            }
        }

        Item { width: parent.width; height: parent.width*0.03; visible: preview.day.count > 0 }

        DayChart {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: preview.day.count > 0
            width: parent.width*0.8
            height: app.height*0.3
            day: new Date()
            bars: preview.day.buckets
            ticks: preview.day.count > 0 ? Stats.heartRateAxis(preview.day.min, preview.day.max).ticks : [40, 80, 120]
            highlight: preview.day.latestBucket
        }
    }
    onClicked: pageStack.push(detailPage)
    Component {
        id: detailPage
        HeartrateDetailPage {}
    }
}
