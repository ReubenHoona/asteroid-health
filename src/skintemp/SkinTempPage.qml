/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

import "../data"
import "../data/HealthStats.js" as Stats
import "../data/HealthFormat.js" as Format
import "../graphs"
import "../theme"
import "../ui"

// The Skin temp variation card's page of stock (SkinTempDetailsViewModel.java, aage.java, acbf.java o()): the card's
// state ("In range", "Above range", "Below range", "Wear to sleep N more times", ...) with "Last sleep session"; the
// line that explains it while the baseline is made ("Skin temperature variation is the fluctuation in temperature
// taken from your wrist while you sleep"), above range ("May be associated with warmer surroundings or other
// factors") or below; the week's nights against the personal range (a bar: the range, a dot: the night's
// variation) with its legend, and "In range this week": "%1$d of %2$d days". The values are asteroid-sensorlogd's
// (health.db skin_temp_night, HealthData.skinTemp/skinTempWeek; computed on the watch, stock's in the cloud), in
// deg C, or deg F with the watch's unit setting (a difference: x 1.8). HEALTH colours.
HealthPage {
    id: page
    readonly property var tones: HealthPalette.health
    readonly property var view: {
        HealthData.version
        return HealthData.skinTemp(HealthData.today)
    }
    readonly property var week: {
        HealthData.version
        return HealthData.skinTempWeek(HealthData.today)
    }
    readonly property bool fahrenheit: useFahrenheit.value === true
    readonly property var counts: Format.skinTempInRange(week)
    readonly property var ticks: Format.skinTempTicks(week, fahrenheit)

    ConfigurationValue { id: useFahrenheit; key: "/org/asteroidos/settings/use-fahrenheit"; defaultValue: false }

    //% "Skin temp variation"
    title: qsTrId("id-skin-temp-variation")

    function weekModel() {
        var out = []
        for (var i = 0; i < week.length; i++) {
            var n = week[i]
            var day = Stats.addDays(HealthData.today, i - (week.length - 1))
            out.push({ label: day.toLocaleDateString(Qt.locale(), "ddd"), hasData: n.hasVariation === true,
                       lo: Format.skinTempDelta(n.loC, fahrenheit), hi: Format.skinTempDelta(n.hiC, fahrenheit),
                       mark: Format.skinTempDelta(n.devC, fahrenheit), hasMark: n.hasVariation === true })
        }
        return out
    }

    StatBlock {
        objectName: "skinTempState"
        value: HealthText.skinTempStateText(page.view)
        valueRole: "titleMedium"
        valueColor: page.tones.main
        note: Format.skinTempHasValue(page.view.state) ?
                  //% "Last sleep session"
                  qsTrId("id-last-sleep-session") : ""
    }

    Label {
        objectName: "skinTempExplain"
        width: parent.width
        visible: text !== ""
        topPadding: Theme.space.s
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        text: HealthText.skinTempExplanation(page.view.state)
    }

    WeekChart {
        objectName: "skinTempWeek"
        visible: page.counts.total > 0
        width: parent.width
        height: Theme.dp(80)
        days: page.weekModel()
        ticks: page.ticks
        selected: 6
        barColor: page.tones.dark
        markColor: page.tones.main
        Accessible.name:
            //% "Skin temperature variation chart"
            qsTrId("id-skin-temp-chart")
    }

    // the legend: the personal range (the bar) and the nights' dots
    Row {
        objectName: "skinTempLegend"
        visible: page.counts.total > 0
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.dp(6)
        topPadding: Theme.space.s
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.dp(6)
            height: Theme.dp(12)
            radius: width / 2
            color: page.tones.dark
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            role: "bodySmall"
            color: HealthPalette.label
            //% "Personal range"
            text: qsTrId("id-personal-range")
        }
    }

    StatBlock {
        objectName: "skinTempInRange"
        visible: page.counts.total > 0
        //% "In range this week"
        caption: qsTrId("id-in-range-this-week")
        //% "%1 of %2 days"
        //: %1 is the nights of this week in the personal range, %2 the nights with a value (stock plurals 0x7f120123)
        value: qsTrId("id-days-of-days").arg(page.counts.inRange).arg(page.counts.total)
        valueColor: page.tones.main
    }

    Label {
        width: parent.width
        topPadding: Theme.space.l
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        text: qsTrId("id-for-more-data").arg(qsTrId("id-skin-temp-variation")).arg(HealthText.phoneApp)
    }
}
