/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import org.asteroid.relax

import "Breath.js" as Breath

// Relax (health-fitness-03): the guided breathing app of stock, in its own launcher entry. The start page
// (minutes, Settings, Start), the first-run text, the session, the recap and the mood. A finished session is
// written to sensorlogd's data directory (relax/<day>.log: time:seconds:start heart rate:end heart rate; the mood
// to mood/<day>.log).
Application {
    id: app

    property alias log: relaxLog
    // the clock of the sessions: 1 is real time (tests run faster)
    property real timeScale: 1

    RelaxLog {
        id: relaxLog
    }

    ConfigurationValue {
        id: introSeen
        key: "/org/asteroidos/health/relax/intro-seen"
        defaultValue: false
    }

    LayerStack {
        id: stack
        objectName: "relaxStack"
        anchors.fill: parent
        firstPage: Component {
            RelaxStartPage {
                onStartRequested: (minutes) => app.startSession(minutes)
                onSettingsRequested: stack.push(settingsPage)
            }
        }
    }

    Component { id: settingsPage; RelaxSettingsPage {} }
    Component {
        id: introPage
        RelaxIntroPage {
            onContinued: {
                introSeen.value = true
                stack.pop(stack.currentLayer)
            }
        }
    }
    Component {
        id: sessionPage
        RelaxSessionPage {
            onCompleted: (minutes, startedAt, hrStart, hrEnd) => app.finished(minutes, startedAt, hrStart, hrEnd)
            onAborted: stack.pop(stack.currentLayer)
        }
    }
    Component {
        id: recapPage
        RelaxRecapPage {
            id: recap
            onDone: app.toStart()
            onMoodRequested: stack.push(moodPage, { target: recap })
        }
    }
    Component {
        id: moodPage
        RelaxMoodPage {
            id: moods
            property var target: null
            onChosen: (mood) => {
                if (target)
                    target.mood = mood
                relaxLog.logMood(Date.now(), mood)
                stack.pop(stack.currentLayer)
            }
        }
    }

    function startSession(minutes) {
        stack.push(sessionPage, { minutes: minutes, timeScale: app.timeScale })
    }

    // the last breath is out: log the session, show the recap over it
    function finished(minutes, startedAt, hrStart, hrEnd) {
        relaxLog.logSession(startedAt, Math.round(minutes * 60), hrStart, hrEnd)
        stack.push(recapPage, { hrStart: hrStart, hrEnd: hrEnd })
    }

    function toStart() {
        while (stack.layers.length > 0)
            stack.pop(stack.currentLayer)
    }

    // the text of the first run comes over the start page
    Component.onCompleted: {
        if (introSeen.value !== true)
            stack.push(introPage)
    }
}
