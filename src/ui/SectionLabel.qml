/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"

// The sub-header of a group on a detail page ('Last 7 days', 'In heart rate zones'): the list
// sub-header of stock (titleSmall, 12 dp above and 8 dp below).
Item {
    id: section
    property alias text: label.text
    property color color: HealthPalette.label

    width: parent ? parent.width : Theme.dp(180)
    height: label.implicitHeight + Theme.space.l + Theme.space.m

    Accessible.role: Accessible.Heading
    Accessible.name: text

    Label {
        id: label
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Theme.space.l
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "titleSmall"
        color: section.color
    }
}
