/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"

/*
 * The main goal ring that heads the Health list (health-fitness-02): the steps of today in a ring that
 * fills towards the goal (FITNESS colours, the track #2D3130), the count in it and '3,760 left' /
 * 'Goal met' / '120 over goal' under it. Stock draws a Lottie loop (maingoal-loop, 5.02 s) in the
 * ring; here the ring fills once when it appears (a spring, Motion default effects) and rests: nothing
 * animates while the page is still, so the display and the CPU idle.
 */
MouseArea {
    id: goal
    property real fraction: 0
    property string value: ""
    property string caption: ""
    property string subtitle: ""
    property string iconName: "eos-health-steps"
    readonly property var tones: HealthPalette.fitness
    // the ring as drawn
    property real shown: 0
    readonly property real ringSize: Theme.dp(100)
    readonly property real stroke: Theme.dp(8)

    implicitHeight: ringSize + Theme.dp(8) + subtitleLabel.implicitHeight
    Accessible.role: Accessible.Button
    Accessible.name: caption + " " + value + " " + subtitle

    Behavior on shown {
        NumberAnimation {
            duration: Motion.springDuration(Motion.standard.defaultEffects.stiffness)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.springEasing
        }
    }
    onFractionChanged: shown = fraction
    Component.onCompleted: shown = fraction

    Item {
        id: ringBox
        anchors.horizontalCenter: parent.horizontalCenter
        width: goal.ringSize
        height: width

        ProgressArc {
            anchors.fill: parent
            strokeWidth: goal.stroke
            color: HealthPalette.track
            sweepAngle: 360
        }
        ProgressArc {
            objectName: "goalArc"
            anchors.fill: parent
            strokeWidth: goal.stroke
            color: goal.tones.main
            sweepAngle: 360 * goal.shown
            visible: goal.shown > 0
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: goal.iconName
                color: goal.tones.main
                width: Theme.size.iconSmall
                height: width
            }
            Label {
                objectName: "goalValue"
                anchors.horizontalCenter: parent.horizontalCenter
                text: goal.value
                role: "titleLarge"
                color: goal.tones.main
                font.features: Theme.tabularNumerals
            }
        }
    }
    Label {
        id: subtitleLabel
        objectName: "goalSubtitle"
        anchors {
            top: ringBox.bottom
            topMargin: Theme.dp(4)
            left: parent.left
            right: parent.right
        }
        horizontalAlignment: Text.AlignHCenter
        text: goal.subtitle
        role: "labelMedium"
        color: HealthPalette.label
        maximumLineCount: 2
        wrapMode: Text.Wrap
    }
}
