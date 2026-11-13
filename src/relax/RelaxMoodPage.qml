/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "Breath.js" as Breath
import "../ui"

// 'Log mood': the eleven moods of stock in its order (strings 0x7f140aed-0x7f140af8). A tap logs the mood
// and goes back to the recap, which then says 'Mood logged'.
HealthPage {
    id: page
    //% "Log mood"
    title: qsTrId("id-relax-log-mood")

    signal chosen(string mood)

    function label(mood) {
        switch (mood) {
        case "calm":
            //% "Calm"
            return qsTrId("id-mood-calm")
        case "content":
            //% "Content"
            return qsTrId("id-mood-content")
        case "excited":
            //% "Excited"
            return qsTrId("id-mood-excited")
        case "frustrated":
            //% "Frustrated"
            return qsTrId("id-mood-frustrated")
        case "happy":
            //% "Happy"
            return qsTrId("id-mood-happy")
        case "neutral":
            //% "Neutral"
            return qsTrId("id-mood-neutral")
        case "pleasant":
            //% "Pleasant"
            return qsTrId("id-mood-pleasant")
        case "sad":
            //% "Sad"
            return qsTrId("id-mood-sad")
        case "stressed":
            //% "Stressed"
            return qsTrId("id-mood-stressed")
        case "unpleasant":
            //% "Unpleasant"
            return qsTrId("id-mood-unpleasant")
        }
        //% "Worried"
        return qsTrId("id-mood-worried")
    }

    Repeater {
        model: Breath.MOODS
        delegate: Button {
            objectName: "mood-" + modelData
            width: page.contentWidth
            variant: "tonal"
            text: page.label(modelData)
            onClicked: page.chosen(modelData)
        }
    }
}
