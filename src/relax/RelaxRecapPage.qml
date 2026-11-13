/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"
import "../ui"

// The end of a session (ytl.java:113-160, zya.java:27-50): 'Session complete' with the relax icon, 'Relax recap'
// with the burst animation, the heart rate at the start and at the end ('- -' where the sensor gave none),
// 'Log mood' (one of eleven moods, then 'Mood logged') and 'Done'.
HealthPage {
    id: page
    //% "Session complete"
    title: qsTrId("id-relax-complete")

    readonly property string none: "- -"
    //% "bpm"
    readonly property string bpmUnit: qsTrId("id-bpm")
    property int hrStart: 0
    property int hrEnd: 0
    // the mood logged ('' none yet)
    property string mood: ""
    readonly property bool moodLogged: mood !== ""
    signal moodRequested()
    signal done()

    Item {
        width: parent.width
        height: Theme.dp(88)
        RecapBurst {
            objectName: "burst"
            anchors.centerIn: parent
        }
        Icon {
            objectName: "relaxIcon"
            anchors.centerIn: parent
            name: "eos-relax"
            color: HealthPalette.wellness.main
            width: Theme.dp(48)
            height: width
        }
    }
    SectionLabel {
        //% "Relax recap"
        text: qsTrId("id-relax-recap")
        color: HealthPalette.wellness.main
    }
    StatBlock {
        objectName: "hrStart"
        //% "Start"
        caption: qsTrId("id-relax-hr-start")
        value: page.hrStart > 0 ? String(page.hrStart) : page.none
        unit: page.hrStart > 0 ? page.bpmUnit : ""
        valueColor: HealthPalette.health.main
    }
    StatBlock {
        objectName: "hrEnd"
        //% "End"
        caption: qsTrId("id-relax-hr-end")
        value: page.hrEnd > 0 ? String(page.hrEnd) : page.none
        unit: page.hrEnd > 0 ? page.bpmUnit : ""
        valueColor: HealthPalette.health.main
    }
    Button {
        objectName: "moodButton"
        width: page.contentWidth
        variant: "tonal"
        iconName: "ios-happy"
        enabled: !page.moodLogged
        text: page.moodLogged ?
            //% "Mood logged"
            qsTrId("id-relax-mood-logged") :
            //% "Log mood"
            qsTrId("id-relax-log-mood")
        onClicked: page.moodRequested()
    }
    Button {
        objectName: "doneButton"
        width: page.contentWidth
        centered: true
        //% "Done"
        text: qsTrId("id-relax-done")
        onClicked: page.done()
    }
}
