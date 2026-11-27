/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration

/*
 * The Today list's last row (R5 E-08), stock's sync section (aawc.java / aari.java:462-466: a spacer, the
 * state text, a small spacer, a tertiary button): "Syncing" while a sync the watch asked for runs, "Can't
 * Sync Data" after one failed, else "Last synced" and when (afzj.A, aibv.w: the time today, the month and
 * day within a year, the date before), "- -" when never; the button "Sync", "Retry" after a failure
 * (afzj.B), not usable while syncing. asteroid-btsyncd keeps the state (healthservice.h): its keys under
 * /org/asteroidos/health/sync/; a press writes "button@<ms>" to its request key, the list's opening
 * "today@<ms>" (stock WEAR_TODAY_APP_OPEN; TodayPage). Shown only once a phone ended a sync here
 * (sync/supported), as stock shows the section only with its phone app.
 */
Column {
    id: row

    // the time now (the tests set it)
    property var now: new Date()

    readonly property bool shown: supported.value === true || supported.value === "true"
    readonly property string phase: syncState.value || "idle"
    readonly property bool syncing: phase === "syncing"
    readonly property bool failed: phase === "failed"
    readonly property real lastMs: Number(lastSync.value) || 0

    function ask(event) {
        request.value = event + "@" + Date.now()
    }

    // aibv.w: the time on the same day, the month and day within a year, the date before
    function whenText(ms, nowDate) {
        if (!(ms > 0))
            //% "- -"
            return qsTrId("id-sync-never")
        var at = new Date(ms)
        var dayStart = function (d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime() }
        var days = Math.round((dayStart(nowDate) - dayStart(at)) / 86400000)
        if (days <= 0)
            return TimeFormat.time(at)
        var l = Qt.locale()
        if (days > 365)
            return l.toString(at, l.dateFormat(Locale.ShortFormat))
        // the month and day in the locale's order (the skeleton MMMMd)
        var dayFirst = l.dateFormat(Locale.LongFormat).search(/d/) < l.dateFormat(Locale.LongFormat).search(/M/)
        return l.toString(at, dayFirst ? "d MMMM" : "MMMM d")
    }

    readonly property string stateText: syncing
                                        //% "Syncing"
                                        ? qsTrId("id-sync-syncing")
                                        : failed
                                          //% "Can't Sync Data"
                                          ? qsTrId("id-sync-failed")
                                          //% "Last synced\n %1"
                                          //: %1 is when: a time today, else a date
                                          : qsTrId("id-sync-last").arg(whenText(lastMs, now))

    visible: shown
    spacing: Dims.l(2)

    ConfigurationValue { id: supported; key: "/org/asteroidos/health/sync/supported"; defaultValue: false }
    ConfigurationValue { id: syncState; key: "/org/asteroidos/health/sync/state"; defaultValue: "idle" }
    ConfigurationValue { id: lastSync; key: "/org/asteroidos/health/sync/last-ms"; defaultValue: 0 }
    ConfigurationValue { id: request; key: "/org/asteroidos/health/sync/request"; defaultValue: "" }

    // stock's medium spacer above the text
    Item { width: 1; height: Dims.l(2) }
    Label {
        objectName: "syncText"
        width: row.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: row.stateText
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
    }
    Button {
        id: button
        objectName: "syncButton"
        width: row.width
        // stock ButtonType.TERTIARY: no container, the label in the middle
        variant: "child"
        centered: true
        enabled: !row.syncing
        text: row.failed
              //% "Retry"
              ? qsTrId("id-sync-retry")
              //% "Sync"
              : qsTrId("id-sync-button")
        onClicked: row.ask("button")
    }
}
