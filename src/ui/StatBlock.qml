/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../theme"

/*
 * A caption, a value (with its unit) and a note, centred: the stat blocks of the detail pages
 * ('Average steps' 5,210; 'Best day' ...). Colours follow the metric's category.
 */
Column {
    id: block
    property string caption: ""
    property string value: ""
    property string unit: ""
    property string note: ""
    property string noteBottom: ""
    property color valueColor: HealthPalette.fitness.main
    property string valueRole: "titleLarge"
    // the value is a sentence (a state: "Wear your watch to sleep"), not a number: it wraps inside the round screen's
    // safe width, centred, as stock's cards' text does
    property bool textValue: false
    readonly property alias valueLabel: valueText
    readonly property alias captionLabel: captionText
    readonly property alias noteLabel: noteText
    width: parent ? parent.width : Theme.dp(180)
    spacing: Theme.dp(4)

    Label {
        id: captionText
        width: parent.width
        visible: text !== ""
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        maximumLineCount: 2
        text: block.caption
        role: "labelMedium"
        color: HealthPalette.label
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.dp(3)
        Label {
            id: valueText
            width: block.textValue ? Math.round(block.width * 0.84) : implicitWidth
            wrapMode: block.textValue ? Text.Wrap : Text.NoWrap
            maximumLineCount: block.textValue ? 3 : 1
            horizontalAlignment: Text.AlignHCenter
            text: block.value
            role: block.valueRole
            color: block.valueColor
            font.features: Theme.tabularNumerals
        }
        Label {
            visible: text !== ""
            anchors.baseline: valueText.baseline
            text: block.unit
            role: "bodyMedium"
            color: HealthPalette.label
        }
    }
    Label {
        id: noteText
        width: parent.width
        visible: text !== ""
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        maximumLineCount: 3
        text: block.note
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
    }
    Label {
        width: parent.width
        visible: text !== ""
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        maximumLineCount: 2
        text: block.noteBottom
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
    }
}
