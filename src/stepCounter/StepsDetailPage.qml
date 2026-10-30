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

// The steps of a day, as the stock Fitbit steps view: the day's count and
// how far it is to the goal, the steps of every hour, and the last seven
// days with the goal line (a day without data keeps its place). The day
// before or after: the arrows next to the date, or a swipe across the day.
Item {
    id: root
    property date currentDay: new Date()
    property date today: new Date()
    property date weekEnd: currentDay
    property var day: Stats.stepsDay([], currentDay)
    property int dayTotal: 0
    property var week: []
    property var weekTicks: [0, 5000, 10000]
    property int weekSelected: 6
    property int weekAverage: -1
    readonly property bool isToday: Stats.daysBetween(currentDay, today) === 0
    // the user's goal, else the stock default (read when the page opens)
    property int goal: Stats.DEFAULT_STEP_GOAL
    property bool logging: true
    property var cache: ({})

    StepsDataLoader {
        id: stepsDataLoader
        Component.onCompleted: triggerDaemonRecording()
        onDataChanged: {
            delete root.cache[Stats.dayKey(new Date())]
            delete root.cache[Stats.dayKey(Stats.addDays(new Date(), -1))]
            root.reload()
        }
        onTodayTotalChanged: if (root.isToday) root.dayTotal = root.totalOf(root.currentDay, root.day)
    }

    function summaryOf(d) {
        var key = Stats.dayKey(d)
        if (cache[key] === undefined)
            cache[key] = Stats.stepsDay(stepsDataLoader.getDataForDate(Stats.addDays(d, 0)), d)
        return cache[key]
    }

    // today: the live count when it is ahead of the log
    function totalOf(d, s) {
        return Stats.daysBetween(d, today) === 0 ? Math.max(s.total, stepsDataLoader.todayTotal) : s.total
    }

    function reload() {
        day = summaryOf(currentDay)
        dayTotal = totalOf(currentDay, day)
        var first = Stats.addDays(weekEnd, -6)
        var days = []
        var hi = goal
        var sum = 0
        var counted = 0
        for (var i = 0; i < 7; i++) {
            var d = Stats.addDays(first, i)
            var s = summaryOf(d)
            var total = totalOf(d, s)
            var hasData = s.count > 0 || total > 0
            days.push({ label: d.toLocaleDateString(Qt.locale(), "ddd"), hasData: hasData, lo: 0, hi: total, mark: -1 })
            hi = Math.max(hi, total)
            if (hasData) {
                sum += total
                counted++
            }
        }
        weekTicks = Stats.stepsAxis(hi).ticks
        week = days
        weekSelected = Stats.daysBetween(first, currentDay)
        weekAverage = counted ? Math.round(sum / counted) : -1
    }

    function showDay(d) {
        if (Stats.daysBetween(d, today) < 0)
            return
        currentDay = Stats.addDays(d, 0)
        if (Stats.daysBetween(weekEnd, currentDay) > 0) {
            var end = Stats.addDays(currentDay, 6)
            weekEnd = Stats.daysBetween(end, today) < 0 ? Stats.addDays(today, 0) : end
        } else if (Stats.daysBetween(currentDay, Stats.addDays(weekEnd, -6)) > 0) {
            weekEnd = currentDay
        }
        reload()
        dayFade.restart()
    }

    function hourBars() {
        var bars = []
        for (var h = 0; h < 24; h++)
            bars.push(day.hours[h] > 0 ? { lo: 0, hi: day.hours[h] } : null)
        return bars
    }

    function maxHour() {
        return Math.max.apply(null, day.hours)
    }

    function noDataText() {
        if (!logging)
            //% "Step logging is off"
            return qsTrId("id-steps-logging-off")
        if (isToday)
            //% "Nothing logged yet today"
            return qsTrId("id-nothing-yet-today")
        //% "Watch not worn"
        return qsTrId("id-not-worn")
    }

    Component.onCompleted: {
        if (loggerSettings.stepGoalEnabled && loggerSettings.stepGoalTarget > 0)
            goal = loggerSettings.stepGoalTarget
        logging = loggerSettings.stepCounterEnabled
        currentDay = Stats.addDays(currentDay, 0)
        // the week of the overview's chart (the last 7 days) if it holds the day
        weekEnd = Stats.daysBetween(currentDay, today) <= 6 ? Stats.addDays(today, 0) : currentDay
        reload()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            var wasToday = root.isToday
            root.today = new Date()
            if (wasToday && !root.isToday)
                root.reload()
        }
    }

    // three screens: the day at a glance, the day's hours, the week; the
    // page rests on one of them
    SectionFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: contentColumn.height
        sections: contentColumn
        Column {
            id: contentColumn
            width: parent.width

            DaySwipeArea {
                width: parent.width
                height: root.height
                onPrevious: root.showDay(Stats.addDays(root.currentDay, -1))
                onNext: root.showDay(Stats.addDays(root.currentDay, 1))

                Column {
                    id: glance
                    width: parent.width
                    y: Math.max(Dims.h(8), (parent.height - height) / 2 - Dims.h(3))
                    readonly property bool hasData: root.day.count > 0 || root.dayTotal > 0

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        //% "Steps"
                        text: qsTrId("id-steps")
                        font {
                            styleName: "SemiCondensed Light"
                            pixelSize: Dims.l(7)
                        }
                    }

                    DayNavigator {
                        id: nav
                        width: parent.width
                        day: root.currentDay
                        today: root.today
                        onPrevious: root.showDay(Stats.addDays(root.currentDay, -1))
                        onNext: root.showDay(Stats.addDays(root.currentDay, 1))
                    }

                    Column {
                        width: parent.width
                        NumberAnimation on opacity { id: dayFade; from: 0.3; to: 1; duration: 150; running: false }

                        Item { width: parent.width; height: Dims.h(2) }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Dims.l(2)
                            visible: glance.hasData
                            Icon {
                                name: "ios-walk"
                                width: Dims.l(9)
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                text: root.dayTotal.toLocaleString(Qt.locale(), "f", 0)
                                font.pixelSize: Dims.l(15)
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: glance.hasData
                            text: root.dayTotal >= root.goal ?
                                //% "Goal of %1 reached"
                                //: %1 is the daily step goal
                                qsTrId("id-steps-goal-reached").arg(root.goal.toLocaleString(Qt.locale(), "f", 0)) :
                                //% "of %1 steps"
                                //: %1 is the daily step goal
                                qsTrId("id-steps-of-goal").arg(root.goal.toLocaleString(Qt.locale(), "f", 0))
                            font.pixelSize: Dims.l(5.5)
                            opacity: 0.8
                        }
                        Item { width: parent.width; height: Dims.h(5); visible: glance.hasData }
                        // how far to the goal
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: glance.hasData
                            width: Dims.w(56)
                            height: Dims.l(2)
                            radius: height / 2
                            color: "#33FFFFFF"
                            Rectangle {
                                width: Math.max(parent.height, parent.width * Math.min(1, root.dayTotal / root.goal))
                                height: parent.height
                                radius: height / 2
                                color: root.dayTotal >= root.goal ? "#10FF1C" : "#FFFFFF"
                            }
                        }

                        // nothing logged that day
                        Item { width: parent.width; height: Dims.h(4); visible: !glance.hasData }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: !glance.hasData
                            //% "No data"
                            text: qsTrId("id-no-data")
                            font.pixelSize: Dims.l(9)
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Dims.w(70)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: !glance.hasData
                            text: root.noDataText()
                            font.pixelSize: Dims.l(5.5)
                            opacity: 0.8
                        }
                    }
                }
            }

            // the day: the steps of every hour, this hour brightest
            DaySwipeArea {
                width: parent.width
                height: root.height
                visible: root.day.count > 0
                onPrevious: root.showDay(Stats.addDays(root.currentDay, -1))
                onNext: root.showDay(Stats.addDays(root.currentDay, 1))

                Column {
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Dims.h(3)
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: nav.dayName(root.currentDay)
                        font.pixelSize: Dims.l(6)
                    }
                    DayChart {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Dims.w(80)
                        height: Dims.h(42)
                        day: root.currentDay
                        capped: false
                        bars: root.day.count > 0 ? root.hourBars() : []
                        ticks: Stats.stepsAxis(root.day.count > 0 ? root.maxHour() : 1).ticks
                        highlight: root.isToday ? root.today.getHours() : -1
                    }
                }
            }

            // the week: each day's steps and the goal line
            Item {
                width: parent.width
                height: root.height

                Column {
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Dims.h(3)

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Stats.daysBetween(root.weekEnd, root.today) === 0 ?
                            //% "Last 7 days"
                            qsTrId("id-last-7-days") :
                            Stats.addDays(root.weekEnd, -6).toLocaleDateString(Qt.locale(), "d MMM") + " – " + root.weekEnd.toLocaleDateString(Qt.locale(), "d MMM")
                        font.pixelSize: Dims.l(6)
                    }

                    WeekChart {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Dims.w(80)
                        height: Dims.h(40)
                        days: root.week
                        ticks: root.weekTicks
                        selected: root.weekSelected
                        goal: root.goal
                        capped: false
                        markColor: "#10FF1C"
                        onDayClicked: (index) => root.showDay(Stats.addDays(root.weekEnd, index - 6))
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.weekAverage >= 0
                        //% "Average %1 steps"
                        //: %1 is a number of steps
                        text: qsTrId("id-steps-average").arg(root.weekAverage.toLocaleString(Qt.locale(), "f", 0))
                        font.pixelSize: Dims.l(4.5)
                        opacity: 0.8
                    }
                }
            }
        }
    }
}
