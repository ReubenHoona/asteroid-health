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

MouseArea {
    id: preview
    implicitHeight: contentColumn.implicitHeight
    // the user's goal, else the stock default
    property int goal: Stats.DEFAULT_STEP_GOAL
    property var week: []
    property var ticks: [0, 5000, 10000]

    // the last 7 days, today last; a day without data keeps its place
    function loadData() {
        var today = new Date()
        var days = []
        var hi = goal
        for (var i = 6; i >= 0; i--) {
            var d = Stats.addDays(today, -i)
            var total = i === 0 ? stepsDataLoader.todayTotal : stepsDataLoader.getTotalForDate(d)
            days.push({ label: d.toLocaleDateString(Qt.locale(), "ddd"), hasData: total > 0, lo: 0, hi: total, mark: -1 })
            hi = Math.max(hi, total)
        }
        ticks = Stats.stepsAxis(hi).ticks
        week = days
    }

    StepsDataLoader {
        id: stepsDataLoader
        Component.onCompleted: {
            if (loggerSettings.stepGoalEnabled && loggerSettings.stepGoalTarget > 0)
                preview.goal = loggerSettings.stepGoalTarget
            triggerDaemonRecording()
            preview.loadData()
        }
        onDataChanged: preview.loadData()
    }

    Column {
        id: contentColumn
        width: parent.width

        Label {
            width: parent.width*0.8
            anchors.horizontalCenter: parent.horizontalCenter
            text: stepsDataLoader.todayTotal ?
                //% "You've walked %1 steps today, keep it up!"
                //: %1 is the number of steps
                qsTrId("id-steps-walked-today").arg(stepsDataLoader.todayTotal.toLocaleString(Qt.locale(), "f", 0)) :
                //% "You haven't yet logged any steps today"
                qsTrId("id-no-steps-today")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Item { width: parent.width; height: parent.width*0.1}
        Label {
            anchors {
                left: parent.left
                margins: app.width*0.1
            }
            //% "Steps"
            text: qsTrId("id-steps")
        }

        Item { width: parent.width; height: parent.width*0.05}

        WeekChart {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width*0.8
            height: app.width*0.45
            days: preview.week
            ticks: preview.ticks
            selected: 6
            goal: preview.goal
            capped: false
            markColor: "#10FF1C"
            onDayClicked: (index) => pageStack.push(detailPage, {"currentDay": Stats.addDays(new Date(), index - 6)})
        }
    }
    onClicked: pageStack.push(detailPage)
    Component {
        id: detailPage
        StepsDetailPage {}
    }
}
