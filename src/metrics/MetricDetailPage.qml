/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../data"
import "../data/HealthStats.js" as Stats
import "../data/HealthFormat.js" as Format
import "../graphs"
import "../theme"
import "../ui"

// The detail page of one of the Health cards that has no page of its own: Energy burned, Distance,
// Floors, Active Zone Minutes and Hourly activity (route details/<stat>, health-fitness-02): today's
// value, today by the hour where the day has one (Hourly activity: the steps of every hour against the
// 250 that count), the last 7 days with today's bar brightest, and the week's average. All in the
// FITNESS colours. `metric` is one of "energy", "distance", "floors", "azm", "hourly".
HealthPage {
    id: page
    property string metric: "energy"
    readonly property var tones: HealthPalette.fitness
    readonly property date today: HealthData.today
    readonly property var days: { HealthData.version; return HealthData.week(HealthData.today) }
    readonly property var todaySummary: days[6].summary
    readonly property bool imperial: HealthText.imperial

    // a day's value in the page's unit
    function valueOf(s) {
        switch (metric) {
        case "energy": return Format.energyValue(s.energyKcal)
        case "distance": return Format.distance(s.distanceM, imperial).value
        case "floors": return s.floors || 0
        case "azm": return s.azm || 0
        case "hourly": return s.hoursMet || 0
        }
        return 0
    }

    function unitText() {
        switch (metric) {
        case "energy":
            //% "Cal"
            return qsTrId("id-unit-cal")
        case "distance":
            return Format.distance(1, imperial).unit
        case "hourly":
            //% "hr"
            return qsTrId("id-unit-hr")
        }
        return ""
    }

    function valueText(v) {
        if (metric === "distance")
            return v.toLocaleString(Qt.locale(), "f", 2)
        return HealthText.number(v)
    }

    function titleText() {
        switch (metric) {
        case "energy":
            //% "Energy burned"
            return qsTrId("id-energy-burned")
        case "distance":
            //% "Distance"
            return qsTrId("id-distance")
        case "floors":
            //% "Floors"
            return qsTrId("id-floors")
        case "azm":
            //% "Active Zone Minutes"
            return qsTrId("id-azm")
        }
        //% "Hourly activity"
        return qsTrId("id-hourly-activity")
    }

    function noteText() {
        var s = todaySummary
        if (metric === "azm")
            //% "%1 of %2 this week"
            //: %1 is the Active Zone Minutes of this week so far, %2 the weekly goal (150)
            return qsTrId("id-azm-week").arg(HealthText.number(HealthData.azmWeek(today))).arg(HealthText.number(HealthData.metrics.azmWeeklyGoal))
        if (metric === "hourly")
            return HealthText.hourlyText(s.hoursMet || 0, s.hoursTotal || 0)
        return ""
    }

    // the hour axis: 0, the 250 steps that count, and the most of any hour (at least 500)
    function hourTicks() {
        var hs = todaySummary.hourSteps || []
        var hi = Math.max(500, Math.ceil(Math.max.apply(null, hs.length ? hs : [0]) / 250) * 250)
        return [0, 250, hi]
    }

    function weekModel() {
        var out = []
        for (var i = 0; i < 7; i++) {
            var v = valueOf(days[i].summary)
            out.push({ label: days[i].date.toLocaleDateString(Qt.locale(), "ddd"), hasData: v > 0, lo: 0, hi: v, mark: -1 })
        }
        return out
    }

    function weekMax() {
        var hi = metric === "hourly" ? (todaySummary.hoursTotal || 9) : 1
        for (var i = 0; i < 7; i++)
            hi = Math.max(hi, valueOf(days[i].summary))
        return hi
    }

    function weekTicks() {
        var hi = weekMax()
        // whole units, except a distance shorter than a unit
        return Stats.axis(0, hi, 2, metric === "distance" && hi < 3 ? 0.5 : 1).ticks
    }

    function average() {
        var sum = 0
        var n = 0
        for (var i = 0; i < 7; i++) {
            var v = valueOf(days[i].summary)
            if (v > 0) {
                sum += v
                n++
            }
        }
        return n ? sum / n : -1
    }

    function hourBars() {
        var hs = todaySummary.hourSteps || []
        var bars = []
        for (var h = 0; h < 24; h++)
            bars.push(hs[h] > 0 ? { lo: 0, hi: hs[h] } : null)
        return bars
    }

    title: titleText()

    StatBlock {
        objectName: "metricToday"
        caption: HealthText.dayText(page.today, page.today)
        value: page.valueOf(page.todaySummary) > 0 || page.metric === "hourly" ? page.valueText(page.valueOf(page.todaySummary)) : HealthText.none
        unit: page.valueOf(page.todaySummary) > 0 || page.metric === "hourly" ? page.unitText() : ""
        valueRole: "numeralSmall"
        valueColor: page.tones.main
        note: page.noteText()
    }

    SectionLabel {
        visible: page.metric === "hourly"
        //% "Steps each hour"
        text: qsTrId("id-steps-each-hour")
    }
    DayChart {
        objectName: "metricDayChart"
        visible: page.metric === "hourly"
        width: parent.width
        height: visible ? Theme.dp(80) : 0
        day: page.today
        capped: false
        bars: page.metric === "hourly" ? page.hourBars() : []
        ticks: page.hourTicks()
        goal: 250
        highlight: page.today.getHours()
        barColor: page.tones.main
    }

    SectionLabel {
        text: HealthText.weekText(page.today, page.today)
    }
    WeekChart {
        objectName: "metricWeekChart"
        width: parent.width
        height: Theme.dp(80)
        days: page.weekModel()
        ticks: page.weekTicks()
        selected: 6
        capped: false
        goal: page.metric === "hourly" ? (page.todaySummary.hoursTotal || -1) : -1
        barColor: page.tones.main
    }

    StatBlock {
        objectName: "metricAverage"
        //% "Average"
        caption: qsTrId("id-average")
        value: page.average() >= 0 ? page.valueText(page.average()) : HealthText.none
        unit: page.average() >= 0 ? page.unitText() : ""
        valueColor: page.tones.main
    }
}
