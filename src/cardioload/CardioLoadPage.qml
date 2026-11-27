/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../data"
import "../data/HealthStats.js" as Stats
import "../graphs"
import "../theme"
import "../ui"

// The Cardio load card's page (R5 E-09), as stock's (CardioLoadDetailsViewModel.java: "Cardio load" 0x7f14013b, the
// day's load, "Target %1$d–%2$d" 0x7f140138 with "In target" 0x7f140141 / "Above target" 0x7f140137, "This week"
// 0x7f14015b with the week's loads against the target range, "Target range" 0x7f140159; "See target load in %d
// days", plurals 0x7f120006, while there is no target yet). The numbers are asteroid-sensorlogd's
// (HealthMetricsLoader.cardioLoad: TRIMP of the effort minutes, the target from the 28 days before; stock's target is
// the cloud's). Not copied: the breakdown by activity and the fitness focus (phone). FITNESS colours.
HealthPage {
    id: page
    readonly property var tones: HealthPalette.fitness
    readonly property var load: { HealthData.version; return HealthData.cardioLoad(HealthData.today) }

    //% "Cardio load"
    title: qsTrId("id-cardio-load")

    function weekModel() {
        var out = []
        var week = load.week || []
        for (var i = 0; i < week.length; i++) {
            var v = week[i].load
            out.push({ label: new Date(week[i].date).toLocaleDateString(Qt.locale(), "ddd"), hasData: v > 0, lo: 0,
                       hi: Math.max(0, v), mark: -1 })
        }
        return out
    }
    function weekTicks() {
        var hi = Math.max(10, load.hasTarget ? load.high : 0)
        var week = load.week || []
        for (var i = 0; i < week.length; i++)
            hi = Math.max(hi, week[i].load)
        return Stats.axis(0, hi, 2, 1).ticks
    }

    // the day's load under the title (stock's card at the page's top: the number and its target)
    StatBlock {
        objectName: "cardioToday"
        value: HealthText.number(page.load.load || 0)
        valueRole: "numeralSmall"
        valueColor: page.tones.main
        // with a target: the day against it, the target under; without one yet: the days to one
        note: page.load.hasTarget ? HealthText.cardioStateText(page.load) : HealthText.cardioTargetText(page.load)
        noteBottom: page.load.hasTarget ? HealthText.cardioTargetText(page.load) : ""
    }

    SectionLabel {
        //% "This week"
        text: qsTrId("id-this-week")
    }
    WeekChart {
        objectName: "cardioWeekChart"
        width: parent.width
        height: Theme.dp(80)
        days: page.weekModel()
        ticks: page.weekTicks()
        selected: 6
        capped: false
        // the target's upper end, the line the week's days are held against
        goal: page.load.hasTarget ? page.load.high : -1
        barColor: page.tones.main
    }
    StatBlock {
        objectName: "cardioRange"
        visible: page.load.hasTarget === true
        //% "Target range"
        caption: qsTrId("id-cardio-target-range")
        value: visible ? HealthText.number(page.load.low) + "–" + HealthText.number(page.load.high) : ""
        valueColor: page.tones.main
    }
}
