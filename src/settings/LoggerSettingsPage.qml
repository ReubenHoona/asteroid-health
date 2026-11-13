/*
 * Copyright (C) 2023 Arseniy Movshev <dodoradio@outlook.com>
 *               2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../data"
import "../ui"

// Logging, for developers (stock has no such switches, so only Developer options reaches this page): the
// step and heart rate loggers on or off and their intervals (5 to 60 minutes). Changes apply at once; the
// daemon takes them up once, a second after the last change (reInitLogger).
HealthPage {
    id: page
    //% "Logging"
    title: qsTrId("id-logging")

    readonly property var settings: HealthData.settings
    // what the settings say when the page opens (LoggerSettings has no change signal for these)
    property bool stepLog: true
    property bool hrLog: true
    property int stepMinutes: 10
    property int hrMinutes: 10
    property bool ready: false
    Component.onCompleted: {
        stepLog = settings.stepCounterEnabled
        hrLog = settings.heartrateSensorEnabled
        stepMinutes = Math.round(settings.stepCounterInterval / 60000)
        hrMinutes = Math.round(settings.heartrateSensorInterval / 60000)
        ready = true
    }

    Timer {
        id: apply
        interval: 1000
        onTriggered: page.settings.reInitLogger()
    }

    SwitchButton {
        objectName: "stepLogRow"
        width: page.contentWidth
        //% "Log step count"
        text: qsTrId("id-log-step-count")
        checked: page.stepLog
        onToggled: (value) => { page.stepLog = value; page.settings.stepCounterEnabled = value; apply.restart() }
    }
    IntSelector {
        objectName: "stepIntervalRow"
        width: page.contentWidth
        height: Theme.dp(60)
        value: page.stepMinutes
        min: 5
        max: 60
        stepSize: 1
        unitMarker: " min"
        onValueChanged: if (page.ready && value !== page.stepMinutes) {
            page.stepMinutes = value
            page.settings.stepCounterInterval = value * 60000
            apply.restart()
        }
    }
    SwitchButton {
        objectName: "hrLogRow"
        width: page.contentWidth
        //% "Log heart rate"
        text: qsTrId("id-log-heart-rate")
        checked: page.hrLog
        onToggled: (value) => { page.hrLog = value; page.settings.heartrateSensorEnabled = value; apply.restart() }
    }
    IntSelector {
        objectName: "hrIntervalRow"
        width: page.contentWidth
        height: Theme.dp(60)
        value: page.hrMinutes
        min: 5
        max: 60
        stepSize: 1
        unitMarker: " min"
        onValueChanged: if (page.ready && value !== page.hrMinutes) {
            page.hrMinutes = value
            page.settings.heartrateSensorInterval = value * 60000
            apply.restart()
        }
    }
}
