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

// The heart rate of a day, as the stock Fitbit heart rate view: the latest
// logged reading and when, the day's range and resting heart rate, the day
// as a range bar every half hour, and the last seven days as a bar from each
// day's low to its high with the resting rate as a dot. The day before or
// after: the arrows next to the date, or a swipe across the day.
Item {
    id: root
    property date currentDay: new Date()
    property date today: new Date()
    // the last day of the week chart: the week moves when the day leaves it
    property date weekEnd: currentDay
    property var day: Stats.heartRateDay([], currentDay, 48)
    property var week: []
    property var weekTicks: [40, 80, 120]
    property int weekSelected: 6
    property int restingAverage: -1
    readonly property bool isToday: Stats.daysBetween(currentDay, today) === 0
    // heart rate logging on (read when the page opens)
    property bool logging: true
    // the day summaries read so far (a day file is read when first shown)
    property var cache: ({})

    HrDataLoader {
        id: hrDataLoader
        // a day file changed: only today's (and yesterday's around midnight)
        // are still written
        onDataChanged: {
            delete root.cache[Stats.dayKey(new Date())]
            delete root.cache[Stats.dayKey(Stats.addDays(new Date(), -1))]
            root.reload()
        }
    }

    function summaryOf(d) {
        var key = Stats.dayKey(d)
        if (cache[key] === undefined)
            cache[key] = Stats.heartRateDay(hrDataLoader.getDataForDate(Stats.addDays(d, 0)), d, 48)
        return cache[key]
    }

    function reload() {
        day = summaryOf(currentDay)
        var first = Stats.addDays(weekEnd, -6)
        var days = []
        var lo = Infinity
        var hi = -Infinity
        var restSum = 0
        var restCount = 0
        for (var i = 0; i < 7; i++) {
            var d = Stats.addDays(first, i)
            var s = summaryOf(d)
            days.push({ label: d.toLocaleDateString(Qt.locale(), "ddd"), hasData: s.count > 0,
                        lo: s.min, hi: s.max, mark: s.resting })
            if (s.count > 0) {
                lo = Math.min(lo, s.min)
                hi = Math.max(hi, s.max)
            }
            if (s.resting > 0) {
                restSum += s.resting
                restCount++
            }
        }
        weekTicks = isFinite(lo) ? Stats.heartRateAxis(lo, hi).ticks : [40, 80, 120]
        week = days
        weekSelected = Stats.daysBetween(first, currentDay)
        restingAverage = restCount ? Math.round(restSum / restCount) : -1
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

    function ageText() {
        if (!isToday)
            //% "Last at %1"
            //: %1 is the time of the day's last reading
            return qsTrId("id-hr-last-at").arg(new Date(day.latestTime * 1000).toLocaleTimeString(Qt.locale(), Locale.ShortFormat))
        var m = Stats.minutesAgo(day.latestTime, today.getTime() / 1000)
        if (m < 1)
            //% "Just now"
            return qsTrId("id-hr-just-now")
        if (m < 60)
            //% "%1 min ago"
            //: %1 is a number of minutes
            return qsTrId("id-hr-min-ago").arg(m)
        return new Date(day.latestTime * 1000).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
    }

    function noDataText() {
        if (!logging)
            //% "Heart rate logging is off"
            return qsTrId("id-hr-logging-off")
        if (isToday)
            //% "Nothing logged yet today"
            return qsTrId("id-nothing-yet-today")
        //% "Watch not worn"
        return qsTrId("id-not-worn")
    }

    Component.onCompleted: {
        logging = loggerSettings.heartrateSensorEnabled
        currentDay = Stats.addDays(currentDay, 0)
        // the week of the overview's chart (the last 7 days) if it holds the day
        weekEnd = Stats.daysBetween(currentDay, today) <= 6 ? Stats.addDays(today, 0) : currentDay
        reload()
    }

    Timer {
        // "5 min ago" and today move on
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


    // three screens: the day at a glance, the day's chart, the week
    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: contentColumn.height
        Column {
            id: contentColumn
            width: parent.width

            DaySwipeArea {
                width: parent.width
                height: root.height
                onPrevious: root.showDay(Stats.addDays(root.currentDay, -1))
                onNext: root.showDay(Stats.addDays(root.currentDay, 1))

                Column {
                    width: parent.width
                    y: Math.max(Dims.h(8), (parent.height - height) / 2 - Dims.h(3))

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        //% "Heartrate"
                        text: qsTrId("id-heartrate")
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
                            visible: root.day.count > 0
                            Icon {
                                name: "ios-heart"
                                color: "#FF5A6A"
                                width: Dims.l(9)
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                id: bpmValue
                                text: root.day.latest
                                font.pixelSize: Dims.l(15)
                            }
                            Label {
                                anchors.baseline: bpmValue.baseline
                                //% "bpm"
                                text: qsTrId("id-bpm")
                                font.pixelSize: Dims.l(6)
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.day.count > 0
                            text: root.day.count > 0 ? root.ageText() : ""
                            font.pixelSize: Dims.l(5.5)
                            opacity: 0.8
                        }

                        // nothing logged that day
                        Item { width: parent.width; height: Dims.h(4); visible: root.day.count === 0 }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.day.count === 0
                            //% "No data"
                            text: qsTrId("id-no-data")
                            font.pixelSize: Dims.l(9)
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Dims.w(70)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: root.day.count === 0
                            text: root.noDataText()
                            font.pixelSize: Dims.l(5.5)
                            opacity: 0.8
                        }

                        Item { width: parent.width; height: Dims.h(5); visible: root.day.count > 0 }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.day.count > 0
                            Column {
                                width: Dims.w(32)
                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.day.min === root.day.max ? root.day.min : root.day.min + "–" + root.day.max
                                    font.pixelSize: Dims.l(7)
                                }
                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    //% "Range"
                                    text: qsTrId("id-range")
                                    font.pixelSize: Dims.l(4.5)
                                    opacity: 0.7
                                }
                            }
                            Column {
                                width: Dims.w(32)
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Dims.l(1.5)
                                    Rectangle {
                                        width: Dims.l(2.5)
                                        height: width
                                        radius: width / 2
                                        color: "#FF5A6A"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label {
                                        text: root.day.resting > 0 ? root.day.resting : "–"
                                        font.pixelSize: Dims.l(7)
                                    }
                                }
                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    //% "Resting"
                                    text: qsTrId("id-resting")
                                    font.pixelSize: Dims.l(4.5)
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }
            }

            // the day: a range bar every half hour, the latest brightest
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
                        bars: root.day.buckets
                        ticks: root.day.count > 0 ? Stats.heartRateAxis(root.day.min, root.day.max).ticks : [40, 80, 120]
                        highlight: root.day.latestBucket
                    }
                }
            }

            // the week: each day from its low to its high, the resting rate a dot
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
                        onDayClicked: (index) => root.showDay(Stats.addDays(root.weekEnd, index - 6))
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Dims.l(1.5)
                        Rectangle {
                            width: Dims.l(2.5)
                            height: width
                            radius: width / 2
                            color: "#FF5A6A"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: root.restingAverage > 0 ?
                                //% "Resting, average %1"
                                //: %1 is a heart rate in bpm
                                qsTrId("id-resting-average").arg(root.restingAverage) :
                                qsTrId("id-resting")
                            font.pixelSize: Dims.l(4.5)
                            opacity: 0.8
                        }
                    }
                }
            }
        }
    }
}
