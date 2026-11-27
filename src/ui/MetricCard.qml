/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"

/*
 * One metric of the Health list (health-fitness-02): the metric's icon and name, its value with
 * the unit and a subtitle, all in the metric's category colour (FITNESS, HEALTH or WELLNESS,
 * health-fitness-20), on a Material 3 card. A tap opens the metric's detail page.
 */
Card {
    id: metric
    property string title: ""
    property string iconName: ""
    property string value: ""
    property string unit: ""
    property string subtitle: ""
    // "fitness", "health" or "wellness"
    property string category: "fitness"
    readonly property var tones: HealthPalette.category(category)
    // the value is text, not a number (a night's "7 hr 12 min"): a smaller type
    property bool textValue: false
    // a ring round the icon, the share of a goal (0..1; stock's Sleep card: the time asleep against the sleep goal,
    // aarf.java g(): vhw); below 0: none
    property real progress: -1

    spacing: Theme.dp(2)
    Accessible.name: title + " " + value + " " + unit + " " + subtitle

    Row {
        id: head
        width: parent.width
        spacing: Theme.space.s
        Item {
            id: glyph
            objectName: "cardIcon"
            width: metric.progress >= 0 ? Theme.size.iconSmall + Theme.dp(8) : Theme.size.iconSmall
            height: width
            anchors.verticalCenter: parent.verticalCenter
            Icon {
                anchors.centerIn: parent
                name: metric.iconName
                color: metric.tones.main
                width: Theme.size.iconSmall
                height: width
            }
            ProgressArc {
                visible: metric.progress >= 0
                anchors.fill: parent
                strokeWidth: Theme.dp(2)
                color: HealthPalette.track
                sweepAngle: 360
            }
            ProgressArc {
                objectName: "cardRing"
                visible: metric.progress > 0
                anchors.fill: parent
                strokeWidth: Theme.dp(2)
                color: metric.tones.main
                sweepAngle: 360 * Math.min(1, Math.max(0, metric.progress))
            }
        }
        Label {
            width: parent.width - glyph.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: metric.title
            role: "labelMedium"
            color: metric.tones.main
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
    Row {
        spacing: Theme.dp(3)
        Label {
            id: valueLabel
            // a text value (a state such as "Wear to sleep 3 more times") wraps within the card
            width: metric.textValue ? Math.min(implicitWidth, head.width) : implicitWidth
            wrapMode: metric.textValue ? Text.Wrap : Text.NoWrap
            maximumLineCount: 2
            text: metric.value
            role: metric.textValue ? "titleMedium" : "numeralExtraSmall"
            color: metric.tones.main
            font.features: Theme.tabularNumerals
        }
        Label {
            visible: text !== ""
            anchors.baseline: valueLabel.baseline
            text: metric.unit
            role: "bodyMedium"
            color: HealthPalette.label
        }
    }
    Label {
        width: parent.width
        visible: text !== ""
        text: metric.subtitle
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }
}
