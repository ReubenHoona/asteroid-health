/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

import "Breath.js" as Breath

// The breathing screen: BreathSession with the display held on while it runs (KeepAwake). It starts when the
// page is created and says completed(minutes, startedAt, hrStart, hrEnd) when the last breath is out; leaving
// it (back swipe, the display going off) ends it without a recap.
Item {
    id: page

    // set by the LayerStack
    property int depth
    property var pop

    property int minutes: Breath.DEFAULT_MINUTES
    property real timeScale: 1
    readonly property alias session: breath

    signal completed(int minutes, double startedAt, int hrStart, int hrEnd)
    signal aborted()

    ConfigurationValue {
        id: vibrations
        key: "/org/asteroidos/health/relax/vibrations"
        defaultValue: true
    }

    KeepAwake {
        id: awake
        objectName: "keepAwake"
        active: breath.running
    }

    BreathSession {
        id: breath
        objectName: "breath"
        anchors.fill: parent
        minutes: page.minutes
        timeScale: page.timeScale
        vibrations: vibrations.value !== false
        onCompleted: page.completed(page.minutes, breath.startedAt, breath.hrStart, breath.hrEnd)
        onAborted: page.aborted()
    }

    Component.onCompleted: breath.start()
    Component.onDestruction: breath.stop()
}
