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
import QtSensors
import org.asteroid.controls

import "../data"
import "../data/HealthStats.js" as Stats
import "../data/HealthFormat.js" as Format
import "../graphs"
import "../theme"
import "../ui"

// The heart rate page of stock (HeartRateDetailsViewModel.java:99-125, yrb.java:82-110): 'Heart Rate'
// with the live bpm (the sensor runs only while this page is on the screen and the app is in front),
// 'Heart rate range' of today as '58 - 112 bpm' (or '- -'), a line chart of today (the readings of the
// day, one per minute), 'In heart rate zones' (the minutes of today in each zone, with the zones' bpm),
// the zones of the last 7 days and 'For more Heart rate data, open the ... mobile app'. HEALTH colours.
HealthPage {
    id: page
    readonly property var tones: HealthPalette.health
    readonly property date today: HealthData.today
    readonly property var day: { HealthData.version; return HealthData.heartDay(HealthData.today) }
    readonly property var summary: { HealthData.version; return HealthData.summary(HealthData.today) }
    readonly property var days: { HealthData.version; return HealthData.week(HealthData.today) }
    readonly property var zones: { HealthData.version; return HealthData.metrics.zones() }
    readonly property var zoneMin: Format.zoneMinutes(summary)
    // the live reading of the sensor, 0 until it has one
    property int liveBpm: 0
    // run the sensor only while the page is shown and the app is the front one
    readonly property bool live: visible && Qt.application.active
    // the latest logged reading is recent (stock: within 2 hours)
    readonly property bool fresh: day.count > 0 && Stats.minutesAgo(day.latestTime, today.getTime() / 1000) <= 120
    readonly property bool hasValue: liveBpm > 0 || fresh
    readonly property int shownBpm: liveBpm > 0 ? liveBpm : fresh ? day.latest : 0
    readonly property var zoneColors: [tones.light, tones.main, tones.mid, tones.dark]

    //% "Heart Rate"
    title: qsTrId("id-heart-rate-title")

    Loader {
        active: page.live
        sourceComponent: HrmSensor {
            active: true
            onReadingChanged: {
                if (reading && reading.bpm > 0)
                    page.liveBpm = reading.bpm
            }
        }
    }
    onLiveChanged: if (!live) liveBpm = 0

    function points() {
        var m = Format.minuteMeans(HealthData.heartPoints(today))
        var s = Stats.dayStart(today)
        var span = Stats.dayEnd(today) - s
        var out = []
        for (var i = 0; i < m.length; i++)
            out.push({ x: (m[i].t - s) / span, y: m[i].v })
        return out
    }

    function zoneName(i) {
        switch (i) {
        case 0:
            //% "Light"
            return qsTrId("id-zone-light")
        case 1:
            //% "Moderate"
            return qsTrId("id-zone-moderate")
        case 2:
            //% "Vigorous"
            return qsTrId("id-zone-vigorous")
        }
        //% "Peak"
        return qsTrId("id-zone-peak")
    }

    function zoneValue(i) {
        return [zoneMin.light, zoneMin.moderate, zoneMin.vigorous, zoneMin.peak][i]
    }

    function weekModel() {
        var out = []
        for (var i = 0; i < 7; i++) {
            var z = Format.zoneMinutes(days[i].summary)
            out.push({ label: days[i].date.toLocaleDateString(Qt.locale(), "ddd"), hasData: z.total > 0, lo: 0, hi: z.total, mark: -1 })
        }
        return out
    }

    function weekStacks() {
        var out = []
        for (var i = 0; i < 7; i++) {
            var z = Format.zoneMinutes(days[i].summary)
            out.push([{ value: z.light, color: zoneColors[0] }, { value: z.moderate, color: zoneColors[1] },
                      { value: z.vigorous, color: zoneColors[2] }, { value: z.peak, color: zoneColors[3] }])
        }
        return out
    }

    function weekTicks() {
        var hi = 10
        for (var i = 0; i < 7; i++)
            hi = Math.max(hi, Format.zoneMinutes(days[i].summary).total)
        return Stats.axis(0, hi, 2, 10).ticks
    }

    function axisTicks() {
        return day.count > 0 ? Stats.heartRateAxis(day.min, day.max).ticks : [40, 80, 120]
    }

    // the live value, as a big number with the heart in front
    Item {
        width: parent.width
        height: bpmRow.height + Theme.dp(4)
        Row {
            id: bpmRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.dp(4)
            Icon {
                name: "eos-health-heart"
                color: page.tones.main
                width: Theme.size.iconLarge
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                id: bpmValue
                objectName: "bpmValue"
                text: page.hasValue ? page.shownBpm : HealthText.none
                role: "numeralSmall"
                color: page.tones.main
                font.features: Theme.tabularNumerals
            }
            Label {
                anchors.baseline: bpmValue.baseline
                //% "bpm"
                text: qsTrId("id-bpm")
                role: "bodyMedium"
                color: HealthPalette.label
            }
        }
    }
    Label {
        objectName: "bpmNote"
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        text: page.liveBpm > 0 ? "" : page.fresh ? HealthText.ageText(page.day.latestTime, page.today.getTime()) :
            page.day.count > 0 ?
                //% "No recent heart rate"
                qsTrId("id-no-recent-hr") :
                //% "No heart rate data has been collected in the last 2 hrs."
                qsTrId("id-no-hr-2h")
        visible: text !== ""
    }

    StatBlock {
        objectName: "hrRange"
        //% "Heart rate range"
        caption: qsTrId("id-hr-range")
        value: Format.range(page.day.min, page.day.max, page.day.count).has ?
            //% "%1 - %2"
            //: %1 and %2 are the lowest and highest heart rate of today
            qsTrId("id-hr-range-values").arg(page.day.min).arg(page.day.max) : HealthText.none
        unit: page.day.count > 0 ? qsTrId("id-bpm") : ""
        valueColor: page.tones.main
    }

    SectionLabel {
        //% "Today"
        text: qsTrId("id-today")
    }
    DayChart {
        objectName: "hrDayChart"
        width: parent.width
        height: Theme.dp(80)
        day: page.today
        capped: false
        points: page.day.count > 0 ? page.points() : []
        ticks: page.axisTicks()
        lineColor: page.tones.main
        Accessible.name:
            //% "Line chart with heart rate data for today."
            qsTrId("id-hr-chart-today")
    }

    SectionLabel {
        //% "In heart rate zones"
        text: qsTrId("id-in-zones")
    }
    Repeater {
        model: 4
        delegate: Item {
            objectName: "zoneRow" + index
            width: page.contentWidth
            height: Math.max(zoneLabel.implicitHeight, Theme.dp(24)) + Theme.dp(4)
            Rectangle {
                id: swatch
                width: Theme.dp(10)
                height: width
                radius: width / 2
                color: page.zoneColors[index]
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.dp(8)
            }
            Label {
                id: zoneLabel
                anchors {
                    left: swatch.right
                    leftMargin: Theme.dp(6)
                    verticalCenter: parent.verticalCenter
                }
                text: page.zoneName(index)
                role: "labelMedium"
                color: Theme.color.onSurface
            }
            Label {
                objectName: "zoneMinutes" + index
                anchors {
                    right: parent.right
                    rightMargin: Theme.dp(8)
                    verticalCenter: parent.verticalCenter
                }
                //% "%1 min"
                //: %1 is a number of minutes
                text: qsTrId("id-duration-min").arg(page.zoneValue(index))
                role: "labelMedium"
                color: page.zoneColors[index]
                font.features: Theme.tabularNumerals
            }
        }
    }
    Label {
        objectName: "zoneNote"
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        text: HealthData.metrics.restingHr() > 0 ?
            //% "Heart rate zones based on age and your %1 bpm RHR."
            qsTrId("id-zones-rhr").arg(HealthData.metrics.restingHr()) :
            //% "Heart rate zones based on age and your - - bpm RHR."
            qsTrId("id-zones-rhr-none")
    }

    SectionLabel {
        text: HealthText.weekText(page.today, page.today)
    }
    WeekChart {
        objectName: "hrZoneWeek"
        width: parent.width
        height: Theme.dp(80)
        days: page.weekModel()
        stacks: page.weekStacks()
        ticks: page.weekTicks()
        selected: 6
        Accessible.name:
            //% "Bar chart with accumulated heart rate zone data for the week."
            qsTrId("id-hr-zone-week-chart")
    }

    Label {
        objectName: "hrFooter"
        width: parent.width
        topPadding: Theme.space.l
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        //% "For more %1 data, open the %2 mobile app"
        //: %1 is the kind of data (Heart rate), %2 the name of the phone app
        text: qsTrId("id-for-more-data").arg(
            //% "Heart rate"
            qsTrId("id-heart-rate")).arg(HealthText.phoneApp)
    }
}
