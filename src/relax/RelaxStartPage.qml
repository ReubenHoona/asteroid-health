/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "Breath.js" as Breath
import "../theme"

// Relax's first screen (health-fitness-03; zxp.java:158-163, 218-226, 289-290, 322): the title 'Breathe' 16 dp
// from the top, a minutes picker from 1 to 15 with 2 selected, its items 68 x 82 dp with -8 dp between them
// and 'min' beside it (a crown turn changes it), a Settings icon button and 'Start' with a forward icon. Where
// stock reads it out: '%d minutes' and 'Use 2-finger swipe, or turn crown or bezel to change'.
Item {
    id: page

    // set by the LayerStack
    property int depth
    property var pop

    property alias minutes: picker.minutes
    signal startRequested(int minutes)
    signal settingsRequested()

    Label {
        id: title
        objectName: "breatheTitle"
        anchors {
            top: parent.top
            topMargin: Theme.dp(16) + Theme.margin.scaffoldVertical
            horizontalCenter: parent.horizontalCenter
        }
        //% "Breathe"
        text: qsTrId("id-relax-breathe")
        role: "titleMedium"
        color: Theme.color.onBackground
    }

    // the minutes: the picker, 'min' to its right
    Item {
        id: pickerBox
        anchors {
            top: title.bottom
            bottom: buttons.top
            horizontalCenter: parent.horizontalCenter
        }
        width: Theme.dp(68) + Theme.dp(8) + minLabel.implicitWidth
        clip: true
        Accessible.role: Accessible.SpinBox
        Accessible.name:
            //% "%1 minutes"
            //: %1 is the minutes of the session
            qsTrId("id-relax-minutes-a11y").arg(picker.minutes)
        Accessible.description:
            //% "Use 2-finger swipe, or turn crown or bezel to change"
            qsTrId("id-relax-picker-hint")

        Picker {
            id: picker
            objectName: "minutesPicker"
            property int minutes: selectedOption + Breath.MIN_MINUTES
            x: 0
            // two options tall, centred in the box: the box clips it to the room between the title and the
            // buttons, so the selected number is at the middle of the picker, full size
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.dp(68)
            height: Theme.dp(82) * 2
            count: Breath.MAX_MINUTES - Breath.MIN_MINUTES + 1
            repeatItems: false
            selectedOption: Breath.DEFAULT_MINUTES - Breath.MIN_MINUTES
            optionHeight: Theme.dp(82)
            optionSpacing: -Theme.dp(8)
            role: "numeralMedium"
            textFor: function(option) { return String(option + Breath.MIN_MINUTES) }
        }
        Label {
            id: minLabel
            objectName: "minLabel"
            anchors {
                left: picker.right
                leftMargin: Theme.dp(8)
                verticalCenter: parent.verticalCenter
            }
            //% "min"
            text: qsTrId("id-relax-min")
            role: "labelMedium"
            color: HealthPalette.label
        }
    }

    // the buttons: Settings, then Start
    Row {
        id: buttons
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.dp(30)
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Theme.dp(8)
        IconButton {
            id: settingsButton
            objectName: "settingsButton"
            anchors.verticalCenter: parent.verticalCenter
            size: Theme.size.iconButtonExtraSmall
            variant: "tonal"
            iconName: "ios-settings-outline"
            Accessible.name:
                //% "Settings"
                qsTrId("id-settings")
            onClicked: page.settingsRequested()
        }
        Button {
            id: startButton
            objectName: "startButton"
            width: Theme.dp(96)
            minimumHeight: Theme.size.iconButtonSmall
            horizontalPadding: Theme.space.l
            centered: true
            iconName: "ios-arrow-forward"
            //% "Start"
            text: qsTrId("id-relax-start")
            onClicked: page.startRequested(picker.minutes)
        }
    }
}
