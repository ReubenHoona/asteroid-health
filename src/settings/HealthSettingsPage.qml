/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

import "../data"
import "../ui"

// The Health app's settings, one list that applies a change at once (no Save button, health-fitness-24):
// 'Daily step goal' (the one goal the tile, the complications and the celebration share), 'Reminders to
// move', 'High heart rate' and 'Low heart rate'. The daemon reads a change as soon as it is made
// (LoggerSettings.healthSettingsChanged). Stock keeps these in the phone app and has no logging
// switches: those are on a page that only Developer options shows.
HealthPage {
    id: page
    //% "Settings"
    title: qsTrId("id-settings")

    // a page the list asks for: "goal" (the step goal) or "logging" (developer)
    signal pageRequested(string name)

    readonly property var settings: HealthData.settings
    readonly property bool developer: developerOptions.value === true

    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }

    // the heart rate thresholds in force: the setting, or (0, automatic) the default for the profile
    function highBpm() {
        return settings.hrAlertHighBpm > 0 ? settings.hrAlertHighBpm : HealthData.metrics.defaultHighBpm()
    }
    function lowBpm() {
        return settings.hrAlertLowBpm > 0 ? settings.hrAlertLowBpm : HealthData.metrics.defaultLowBpm()
    }

    Button {
        objectName: "goalRow"
        width: page.contentWidth
        variant: "tonal"
        iconName: "eos-health-steps"
        //% "Daily step goal"
        text: qsTrId("id-daily-step-goal")
        secondaryText: HealthText.number(HealthData.stepGoal)
        onClicked: page.pageRequested("goal")
    }
    SwitchButton {
        objectName: "remindersRow"
        width: page.contentWidth
        //% "Reminders to move"
        text: qsTrId("id-reminders-to-move")
        secondaryText: checked ?
            //% "On"
            qsTrId("id-on") :
            //% "Off"
            qsTrId("id-off")
        checked: page.settings.remindersEnabled
        onToggled: (value) => page.settings.remindersEnabled = value
    }
    SwitchButton {
        objectName: "highRow"
        width: page.contentWidth
        //% "High heart rate"
        text: qsTrId("id-high-heart-rate")
        //% "%1 bpm"
        //: %1 is a heart rate
        secondaryText: qsTrId("id-bpm-value").arg(page.highBpm())
        checked: page.settings.hrAlertHighEnabled
        onToggled: (value) => page.settings.hrAlertHighEnabled = value
    }
    SwitchButton {
        objectName: "lowRow"
        width: page.contentWidth
        //% "Low heart rate"
        text: qsTrId("id-low-heart-rate")
        secondaryText: qsTrId("id-bpm-value").arg(page.lowBpm())
        checked: page.settings.hrAlertLowEnabled
        onToggled: (value) => page.settings.hrAlertLowEnabled = value
    }
    Button {
        objectName: "loggingRow"
        width: page.contentWidth
        visible: page.developer
        variant: "tonal"
        iconName: "ios-settings-outline"
        //% "Logging"
        text: qsTrId("id-logging")
        onClicked: page.pageRequested("logging")
    }
}
