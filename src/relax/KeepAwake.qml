/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import Nemo.KeepAlive

// Keeps the display on while `active`: the breathing session only. It lets go when the session ends, when
// the app goes to the back and when this item is destroyed, so the screen's timeout is never held for longer
// than the session is on the screen.
Item {
    id: keep
    property bool active: false
    readonly property bool held: active && Qt.application.active

    onHeldChanged: DisplayBlanking.preventBlanking = held
    Component.onDestruction: {
        if (held)
            DisplayBlanking.preventBlanking = false
    }
}
