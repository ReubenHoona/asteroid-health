/*
 * Copyright (C) 2023 Arseniy Movshev <dodoradio@outlook.com>
 *               2023 Arseniy Movshev <dodoradio@outlook.com>
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

import "../data"
import "../data/HealthStats.js" as Stats
import "../data/HealthFormat.js" as Format
import "../graphs"
import "../theme"
import "../ui"

// The steps of today and the week, as the stock steps view (StepsDetailsViewModel, abab.java): the
// day's count and its goal, today's chart by hour, the last 7 days with the goal line, then 'Average
// steps', 'Best day' (steps, date, distance) and 'Best hour' (the clock hour in the user's 12 or 24 hour
// format, steps, distance; 'No best hour value' when the week has none). Today and the week, nothing
// older: stock keeps 7 days on the watch and has no day arrows (health-fitness-25).
HealthPage {
    id: page
    readonly property var tones: HealthPalette.fitness
    readonly property date today: HealthData.today
    // read again whenever the data changed
    readonly property var days: { HealthData.version; return HealthData.week(HealthData.today) }
    readonly property var todaySummary: days[6].summary
    readonly property int total: { HealthData.version; return HealthData.stepsOf(HealthData.today) }
    readonly property int goal: HealthData.stepGoal
    readonly property var best: Format.best(days)
    readonly property int average: Format.averageSteps(days)
    readonly property bool hasToday: total > 0

    //% "Steps"
    title: qsTrId("id-steps")

    function hourBars() {
        var bars = []
        var hs = todaySummary.hourSteps || []
        for (var h = 0; h < 24; h++)
            bars.push(hs[h] > 0 ? { lo: 0, hi: hs[h] } : null)
        return bars
    }

    function maxHour() {
        var hs = todaySummary.hourSteps || []
        return Math.max.apply(null, hs.length ? hs : [1])
    }

    function weekModel() {
        var out = []
        for (var i = 0; i < 7; i++) {
            var steps = i === 6 ? total : (days[i].summary.steps || 0)
            out.push({ label: days[i].date.toLocaleDateString(Qt.locale(), "ddd"), hasData: steps > 0, lo: 0, hi: steps, mark: -1 })
        }
        return out
    }

    function weekTicks() {
        var hi = goal
        for (var i = 0; i < days.length; i++)
            hi = Math.max(hi, i === 6 ? total : (days[i].summary.steps || 0))
        return Stats.stepsAxis(hi).ticks
    }

    StatBlock {
        objectName: "stepsToday"
        //% "Today"
        caption: qsTrId("id-today")
        value: page.hasToday ? HealthText.number(page.total) : HealthText.none
        valueRole: "numeralSmall"
        valueColor: page.tones.main
        note: page.hasToday ? HealthText.goalText(page.total, page.goal) :
            //% "No data yet"
            qsTrId("id-no-data-yet")
    }

    SectionLabel {
        //% "Today"
        text: qsTrId("id-today")
        visible: page.hasToday
    }
    DayChart {
        objectName: "stepsDayChart"
        visible: page.hasToday
        width: parent.width
        height: Theme.dp(80)
        day: page.today
        capped: false
        bars: page.hasToday ? page.hourBars() : []
        ticks: Stats.stepsAxis(page.hasToday ? page.maxHour() : 1).ticks
        highlight: page.today.getHours()
        barColor: page.tones.main
    }

    SectionLabel {
        //% "Last 7 days"
        text: qsTrId("id-last-7-days")
    }
    WeekChart {
        objectName: "stepsWeekChart"
        width: parent.width
        height: Theme.dp(80)
        days: page.weekModel()
        ticks: page.weekTicks()
        selected: 6
        goal: page.goal
        capped: false
        barColor: page.tones.main
    }

    StatBlock {
        objectName: "stepsAverage"
        //% "Average steps"
        caption: qsTrId("id-average-steps")
        value: page.average >= 0 ? HealthText.number(page.average) : HealthText.none
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "stepsBestDay"
        //% "Best day"
        caption: qsTrId("id-best-day")
        value: page.best.day ? HealthText.number(page.best.day.steps) : HealthText.none
        valueColor: page.tones.main
        note: page.best.day ? page.best.day.date.toLocaleDateString(Qt.locale(), "dddd d MMM") : ""
        noteBottom: page.best.day ? HealthText.distanceText(page.best.day.distanceM) : ""
    }
    StatBlock {
        objectName: "stepsBestHour"
        //% "Best hour"
        caption: qsTrId("id-best-hour")
        value: page.best.hour ? HealthText.number(page.best.hour.steps) : HealthText.none
        valueColor: page.tones.main
        note: page.best.hour ? TimeFormat.hour(new Date(page.best.hour.date.getFullYear(), page.best.hour.date.getMonth(),
                                                        page.best.hour.date.getDate(), page.best.hour.hour)) :
            //% "No best hour value"
            qsTrId("id-no-best-hour")
        noteBottom: page.best.hour ? HealthText.distanceText(page.best.hour.distanceM) : ""
    }
}
