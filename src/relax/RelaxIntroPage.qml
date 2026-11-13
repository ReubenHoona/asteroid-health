/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"

// The first run (ydo.java:261-290): 'Ready to relax?' and 'Calm your body and mind with a guided breathing
// session', with the relax icon, once. It leaves for the start page by a tap on 'Start'.
Item {
    id: page

    // set by the LayerStack
    property int depth
    property var pop

    signal continued()

    Column {
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Theme.margin.titleSide
            rightMargin: Theme.margin.titleSide
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -Theme.dp(10)
        }
        spacing: Theme.space.s
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "eos-relax"
            color: HealthPalette.wellness.main
            width: Theme.size.iconExtraLarge
            height: width
        }
        Label {
            objectName: "introTitle"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            //% "Ready to relax?"
            text: qsTrId("id-relax-ready")
            role: "titleMedium"
            color: Theme.color.onBackground
        }
        Label {
            objectName: "introText"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            //% "Calm your body and mind with a guided breathing session"
            text: qsTrId("id-relax-intro")
            role: "bodyMedium"
            color: Theme.color.onSurfaceVariant
        }
    }
    Button {
        objectName: "introStart"
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.dp(30)
            horizontalCenter: parent.horizontalCenter
        }
        width: Theme.dp(96)
        minimumHeight: Theme.size.iconButtonSmall
        horizontalPadding: Theme.space.l
        centered: true
        iconName: "ios-arrow-forward"
        text: qsTrId("id-relax-start")
        onClicked: page.continued()
    }
}
