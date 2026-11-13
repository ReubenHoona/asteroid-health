/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtSensors
import org.asteroid.controls

import "Breath.js" as Breath
import "../theme"

// The guided breathing session of Relax (health-fitness-03): two overlapping blobs of 24 % opacity in the
// theme's primary-dim colour swap size every 5 s (the inhale grows with cubic-bezier(0.40, 0, 0.25, 1), the
// exhale with (0.5, 0, 0.5, 1)), the word 'Inhale' for 5000 ms and 'Exhale' for 5000 ms, six breaths a
// minute, the ramp vibration of each phase through ngfd when Vibrations is on. The heart rate at the start
// and at the end comes from the heart rate sensor, which runs only while the session does.
//
// Battery: one animation, running only while the session is on and the display shows the app. When the app
// goes to the back (the display went off) the session ends (aborted): nothing keeps running behind it.
Item {
    id: session

    property int minutes: Breath.DEFAULT_MINUTES
    property bool vibrations: true
    // the session is on
    readonly property bool running: cycle.running
    readonly property int totalBreaths: Breath.breaths(minutes)
    // 'inhale' or 'exhale'
    property string phase: "inhale"
    // the first blob's progress, 0 small to 1 large
    property real p: 0
    // breaths finished, and the time the session started (ms)
    property int breathsDone: 0
    property double startedAt: 0
    // the heart rate at the start (the first reading) and the latest (the end)
    property int hrStart: 0
    property int hrEnd: 0
    // the clock of the animation: 1 is real time (tests run faster)
    property real timeScale: 1
    // the ngfd events of the two phases
    property string inhaleEvent: "relax_inhale"
    property string exhaleEvent: "relax_exhale"
    // the phases begun and the haptic events sent, for the recap and the tests
    property var phases: []
    property var played: []

    signal completed()
    signal aborted()

    readonly property real blobA: Breath.blobSize(p)
    readonly property real blobB: Breath.blobSize(1 - p)

    function start() {
        phases = []
        played = []
        breathsDone = 0
        hrStart = 0
        hrEnd = 0
        p = 0
        startedAt = Date.now()
        cycle.restart()
    }

    function stop() {
        cycle.stop()
    }

    function beginPhase(name) {
        phase = name
        phases.push(name)
        if (vibrations) {
            var ev = name === "inhale" ? inhaleEvent : exhaleEvent
            played.push(ev)
            Haptics.play(ev)
        }
    }

    // the display went off or the app was left: the session ends where it is
    Connections {
        target: Qt.application
        function onActiveChanged() {
            if (!Qt.application.active && cycle.running) {
                cycle.stop()
                session.aborted()
            }
        }
    }

    SequentialAnimation {
        id: cycle
        loops: session.totalBreaths
        ScriptAction { script: session.beginPhase("inhale") }
        NumberAnimation {
            target: session
            property: "p"
            from: 0
            to: 1
            duration: Math.round(Breath.PHASE_MS / session.timeScale)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [Breath.INHALE_CURVE[0], Breath.INHALE_CURVE[1], Breath.INHALE_CURVE[2], Breath.INHALE_CURVE[3], 1, 1]
        }
        ScriptAction { script: session.beginPhase("exhale") }
        NumberAnimation {
            target: session
            property: "p"
            from: 1
            to: 0
            duration: Math.round(Breath.PHASE_MS / session.timeScale)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [Breath.EXHALE_CURVE[0], Breath.EXHALE_CURVE[1], Breath.EXHALE_CURVE[2], Breath.EXHALE_CURVE[3], 1, 1]
        }
        ScriptAction { script: session.breathsDone++ }
        onFinished: session.completed()
    }

    // the heart rate: on only for the session
    Loader {
        active: cycle.running
        sourceComponent: HrmSensor {
            active: true
            onReadingChanged: {
                if (reading && reading.bpm > 0) {
                    if (session.hrStart === 0)
                        session.hrStart = reading.bpm
                    session.hrEnd = reading.bpm
                }
            }
        }
    }

    // the two blobs: each 24 % of the primary-dim colour, one grows while the other shrinks
    Item {
        id: field
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width

        Rectangle {
            objectName: "blobA"
            width: field.width * session.blobA
            height: width
            radius: width / 2
            x: field.width * 0.42 - width / 2
            y: (field.height - height) / 2
            color: Qt.rgba(Theme.color.primaryDim.r, Theme.color.primaryDim.g, Theme.color.primaryDim.b, Breath.BLOB_ALPHA)
        }
        Rectangle {
            objectName: "blobB"
            width: field.width * session.blobB
            height: width
            radius: width / 2
            x: field.width * 0.58 - width / 2
            y: (field.height - height) / 2
            color: Qt.rgba(Theme.color.primaryDim.r, Theme.color.primaryDim.g, Theme.color.primaryDim.b, Breath.BLOB_ALPHA)
        }
        Label {
            objectName: "phaseText"
            anchors.centerIn: parent
            role: "titleLarge"
            color: Theme.color.onBackground
            text: session.phase === "inhale" ?
                //% "Inhale"
                qsTrId("id-relax-inhale") :
                //% "Exhale"
                qsTrId("id-relax-exhale")
        }
    }
}
