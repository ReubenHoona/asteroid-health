/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../data"
import "../theme"

// 'Daily step goal': the one goal of the watch (/org/asteroidos/ux/steps-goal, 10000), set with the
// full-screen stepper (500 to 50,000 in steps of 500) and applied at once.
Item {
    id: page

    // set by the LayerStack
    property int depth
    property var pop

    Stepper {
        id: stepper
        objectName: "goalStepper"
        anchors.fill: parent
        from: 500
        to: 50000
        stepSize: 500
        value: HealthData.stepGoal
        valueText: HealthText.number(value)
        onStepped: (v) => HealthData.settings.stepGoalTarget = Math.round(v)

        Column {
            anchors.centerIn: parent
            spacing: Theme.dp(2)
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Daily step goal"
                text: qsTrId("id-daily-step-goal")
                role: "labelMedium"
                color: HealthPalette.label
            }
            Label {
                objectName: "goalValue"
                anchors.horizontalCenter: parent.horizontalCenter
                text: stepper.valueText
                role: "numeralSmall"
                color: HealthPalette.fitness.main
                font.features: Theme.tabularNumerals
            }
        }
    }
}
