/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../data"
import "../theme"
import "../ui"

// Last night's sleep (the Sleep card's page, health-fitness-02 and -17): the time asleep, the score,
// bedtime and wake-up time in the user's 12 or 24 hour format, the stages (Awake, REM, Light, Deep: minutes
// and share of the night) and the naps. From the night sensorlogd estimated from steps and heart rate
// (SleepDataLoader.lastNight). Without one: 'No data yet'. Under either the sleep goal, 'Goal: %1$s' (R5 E-22: the
// page's head is stock's Sleep card, SleepDetailsViewModel.java:113 aahx.c, aarf.java:441). WELLNESS colours.
HealthPage {
    id: page
    readonly property var tones: HealthPalette.wellness
    readonly property var night: { HealthData.version; return HealthData.sleep() }
    readonly property bool valid: night.valid === true
    readonly property var main: night.main || ({})

    //% "Sleep"
    title: qsTrId("id-sleep")

    function stages() {
        return [
            //% "Awake"
            { name: qsTrId("id-sleep-awake"), minutes: main.awakeMin || 0, pct: main.awakePct || 0, color: tones.light },
            //% "REM sleep"
            { name: qsTrId("id-sleep-rem"), minutes: main.remMin || 0, pct: main.remPct || 0, color: tones.main },
            //% "Light sleep"
            { name: qsTrId("id-sleep-light"), minutes: main.lightMin || 0, pct: main.lightPct || 0, color: tones.mid },
            //% "Deep sleep"
            { name: qsTrId("id-sleep-deep"), minutes: main.deepMin || 0, pct: main.deepPct || 0, color: tones.dark }
        ]
    }

    StatBlock {
        objectName: "sleepDuration"
        caption: page.valid ?
            //% "Last night's sleep"
            qsTrId("id-last-night-sleep") : ""
        value: page.valid ? HealthText.durationText(page.main.asleepMin) : HealthText.none
        valueRole: page.valid ? "titleLarge" : "numeralSmall"
        valueColor: page.tones.main
        note: page.valid ? (page.night.scoreLabel || "") :
            //% "No data yet"
            qsTrId("id-no-data-yet")
        noteBottom: HealthText.sleepGoalText(HealthData.sleepGoalOf(page.night))
    }

    // bedtime and wake-up time, in the user's 12 or 24 hour format (health-fitness-13)
    StatBlock {
        objectName: "sleepBedtime"
        visible: page.valid
        //% "Bedtime"
        caption: qsTrId("id-bedtime")
        value: page.valid ? TimeFormat.time(new Date(page.main.startMs)) : ""
        valueRole: "titleLarge"
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "sleepWake"
        visible: page.valid
        //% "Wake up"
        caption: qsTrId("id-wake-up")
        value: page.valid ? TimeFormat.time(new Date(page.main.endMs)) : ""
        valueRole: "titleLarge"
        valueColor: page.tones.main
    }

    SectionLabel {
        visible: page.valid
        //% "Sleep stages"
        text: qsTrId("id-sleep-stages")
    }
    Repeater {
        model: page.valid ? page.stages() : []
        delegate: Item {
            objectName: "stage" + index
            width: page.contentWidth
            height: stageColumn.height + Theme.dp(8)
            Rectangle {
                id: swatch
                width: Theme.dp(10)
                height: width
                radius: width / 2
                color: modelData.color
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.dp(10)
            }
            // the stage and, under it, its minutes and its share of the night
            Column {
                id: stageColumn
                anchors {
                    left: swatch.right
                    leftMargin: Theme.dp(8)
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                Label {
                    width: parent.width
                    text: modelData.name
                    role: "labelMedium"
                    color: Theme.color.onSurface
                }
                Label {
                    objectName: "stageValue" + index
                    width: parent.width
                    text: HealthText.durationText(modelData.minutes) + " · " + modelData.pct + "%"
                    role: "bodySmall"
                    color: modelData.color
                    font.features: Theme.tabularNumerals
                }
            }
        }
    }

    StatBlock {
        objectName: "sleepNaps"
        visible: page.valid && (page.night.napMin || 0) > 0
        //% "Naps"
        caption: qsTrId("id-sleep-naps")
        value: HealthText.durationText(page.night.napMin || 0)
        valueColor: page.tones.main
    }
}
