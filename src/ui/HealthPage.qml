/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

/*
 * A stock screen of the Health app: a scrolling column whose first item is the title (an M3
 * ListHeader, scrolling away with the page), 4 dp between the items, 5.2 % of the width at each
 * side, 16.64 % of the height above and 36.46 % below so that the last item comes up to the
 * middle of the round screen (CustomDimensions.java:22-24; the same frame as the Settings
 * pages). The crown scrolls the Flickable under the middle of the window (RotaryInput).
 *
 *   HealthPage {
 *       title: "Heart Rate"
 *       StatBlock { caption: "Range"; value: "58 - 112" }
 *   }
 */
Item {
    id: page

    // set by the LayerStack
    property int depth
    property var pop
    property string title: ""
    default property alias content: column.data
    property alias flickable: flick
    property alias column: column
    // the width of the content: the page less the side margins
    readonly property real contentWidth: column.width

    Flickable {
        id: flick
        objectName: "healthFlickable"
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.y + column.height + Math.round(page.height * 0.3646)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: column
            objectName: "healthColumn"
            y: Math.round(page.height * 0.1664)
            x: Math.round(page.width * 0.052)
            width: page.width - 2 * x
            spacing: Theme.space.xs

            ListHeader {
                id: titleHeader
                objectName: "healthTitle"
                visible: page.title !== ""
                text: page.title
                horizontalPadding: Math.round(page.width * 0.12)
                topPadding: Theme.dp(4)
                bottomPadding: Theme.space.l
                label.lineHeight: label.font.pixelSize * 1.1
                EdgeEffect { id: titleEdge; item: titleHeader }
                opacity: titleEdge.alpha
                transform: Scale {
                    origin.x: titleHeader.width / 2
                    origin.y: titleHeader.height / 2
                    xScale: titleEdge.scale
                    yScale: titleEdge.scale
                }
            }
        }
    }
}
