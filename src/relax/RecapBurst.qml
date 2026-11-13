/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"

// The animation behind the Relax recap (stock: a Lottie burst of 2.0 s, then a loop of 5.02 s, 130 x 88 dp;
// the artwork is Google's and is not copied): three rings of the WELLNESS colour spread out and fade in
// 2.0 s, then the rings breathe slowly (5.02 s). It animates only while `active` (the page is on the screen
// and the display is on).
Item {
    id: burst
    property bool active: true
    // 0..1 through the burst, and the loop's phase
    property real spread: 0
    property real pulse: 0
    readonly property real burstMs: 2000
    readonly property real loopMs: 5020
    readonly property bool animating: seq.running

    implicitWidth: Theme.dp(130)
    implicitHeight: Theme.dp(88)

    SequentialAnimation {
        id: seq
        running: burst.active && Qt.application.active
        NumberAnimation {
            target: burst
            property: "spread"
            from: 0
            to: 1
            duration: burst.burstMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.easing.standardDecelerate
        }
        SequentialAnimation {
            loops: Animation.Infinite
            NumberAnimation { target: burst; property: "pulse"; from: 0; to: 1; duration: burst.loopMs / 2; easing.type: Easing.InOutSine }
            NumberAnimation { target: burst; property: "pulse"; from: 1; to: 0; duration: burst.loopMs / 2; easing.type: Easing.InOutSine }
        }
    }

    Repeater {
        model: 3
        delegate: Rectangle {
            readonly property real s: burst.spread * (0.5 + index * 0.25) + burst.pulse * 0.06 * burst.spread
            anchors.centerIn: parent
            width: Math.min(burst.width, burst.height) * s
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Theme.dp(2)
            border.color: HealthPalette.wellness.main
            // the rings fade as they spread
            opacity: Math.max(0, 1 - burst.spread * (0.4 + index * 0.2)) * 0.9 + 0.1 * (1 - index / 3)
        }
    }
}
