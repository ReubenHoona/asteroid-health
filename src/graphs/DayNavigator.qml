/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import org.asteroid.controls

import "../data/HealthStats.js" as Stats

// The shown day with buttons to the day before and after, as the stock
// Fitbit daily view's left and right buttons next to its date
Item {
    id: nav
    property date day: new Date()
    property date today: new Date()
    readonly property bool canGoNext: Stats.daysBetween(day, today) > 0
    signal previous()
    signal next()

    height: Dims.l(12)

    function dayName(d) {
        switch (Stats.dayKind(d, today)) {
        case 0:
            //% "Today"
            return qsTrId("id-today")
        case 1:
            //% "Yesterday"
            return qsTrId("id-yesterday")
        case 2: case 3: case 4: case 5: case 6:
            return d.toLocaleDateString(Qt.locale(), "dddd")
        default:
            return d.toLocaleDateString(Qt.locale(), "ddd d MMM")
        }
    }

    MouseArea {
        id: back
        width: Dims.l(16)
        height: parent.height
        anchors.right: label.left
        onClicked: nav.previous()
        Icon {
            name: "ios-arrow-back"
            width: Dims.l(7)
            height: width
            anchors.centerIn: parent
            opacity: back.containsPress ? 0.6 : 1
        }
    }
    Label {
        id: label
        anchors.centerIn: parent
        width: Dims.w(42)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.pixelSize: Dims.l(6)
        text: nav.dayName(nav.day)
    }
    MouseArea {
        id: forward
        width: Dims.l(16)
        height: parent.height
        anchors.left: label.right
        enabled: nav.canGoNext
        onClicked: nav.next()
        Icon {
            name: "ios-arrow-forward"
            width: Dims.l(7)
            height: width
            anchors.centerIn: parent
            opacity: !forward.enabled ? 0.2 : forward.containsPress ? 0.6 : 1
        }
    }
}
