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

// The resting heart rate card's page of stock (yra.java:137,179-235, aadg.java:69-103): today's resting
// heart rate, 'Average resting HR' over 'Last 7 days' and the line of the last 7 days' resting rates.
// A day's resting rate is the lowest rate held for 30 minutes (HealthStats.restingRate). HEALTH colours.
HealthPage {
    id: page
    readonly property var tones: HealthPalette.health
    readonly property date today: HealthData.today
    // the heart rate summaries of the last 7 days, the oldest first
    readonly property var daySummaries: {
        HealthData.version
        var out = []
        for (var i = 6; i >= 0; i--)
            out.push(HealthData.heartDay(Stats.addDays(HealthData.today, -i)))
        return out
    }
    readonly property int todayResting: daySummaries[6].resting
    readonly property int average: Format.restingAverage(daySummaries)

    //% "Resting heart rate"
    title: qsTrId("id-resting-heart-rate")

    function weekModel() {
        var out = []
        for (var i = 0; i < 7; i++) {
            var r = daySummaries[i].resting
            out.push({ label: Stats.addDays(today, i - 6).toLocaleDateString(Qt.locale(), "ddd"), hasData: r > 0, lo: r, hi: r, mark: r })
        }
        return out
    }

    function weekTicks() {
        var lo = Infinity
        var hi = -Infinity
        for (var i = 0; i < 7; i++) {
            var r = daySummaries[i].resting
            if (r > 0) {
                lo = Math.min(lo, r)
                hi = Math.max(hi, r)
            }
        }
        return isFinite(lo) ? Stats.heartRateAxis(lo, hi).ticks : [40, 60, 80]
    }

    StatBlock {
        objectName: "restingToday"
        caption: HealthText.dayText(page.today, page.today)
        value: page.todayResting > 0 ? String(page.todayResting) : HealthText.none
        unit: page.todayResting > 0 ? qsTrId("id-bpm") : ""
        valueRole: "numeralSmall"
        valueColor: page.tones.main
    }

    StatBlock {
        objectName: "restingAverage"
        //% "Average resting HR"
        caption: qsTrId("id-average-resting-hr")
        value: page.average > 0 ? String(page.average) : HealthText.none
        unit: page.average > 0 ? qsTrId("id-bpm") : ""
        valueColor: page.tones.main
        note: HealthText.weekText(page.today, page.today)
    }

    WeekChart {
        objectName: "restingWeek"
        width: parent.width
        height: Theme.dp(80)
        days: page.weekModel()
        ticks: page.weekTicks()
        line: true
        selected: 6
        markColor: page.tones.main
        Accessible.name:
            //% "Resting heart rate line chart"
            qsTrId("id-resting-chart")
    }

    Label {
        width: parent.width
        topPadding: Theme.space.l
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        //% "For more %1 data, open the %2 mobile app"
        //: %1 is the kind of data (Resting heart rate), %2 the name of the phone app
        text: qsTrId("id-for-more-data").arg(qsTrId("id-resting-heart-rate")).arg(HealthText.phoneApp)
    }
}
