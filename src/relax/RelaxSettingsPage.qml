/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

import "../ui"

// 'Session settings' (zqb.java:180-195): one switch, 'Vibrations', on by default, applied at once. The
// vibration of the breathing phases; the system's vibration switches still apply on top (a session with the
// watch's Vibration off is silent).
HealthPage {
    id: page
    //% "Session settings"
    title: qsTrId("id-relax-session-settings")

    ConfigurationValue {
        id: vibrations
        objectName: "vibrationsKey"
        key: "/org/asteroidos/health/relax/vibrations"
        defaultValue: true
    }

    SwitchButton {
        objectName: "vibrationsRow"
        width: page.contentWidth
        //% "Vibrations"
        text: qsTrId("id-relax-vibrations")
        checked: vibrations.value !== false
        onToggled: (value) => vibrations.value = value
    }
}
