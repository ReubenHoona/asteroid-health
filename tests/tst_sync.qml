/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * R5 E-08 of asteroid-health:
 * - the Today list's last row, stock's sync section (src/today/SyncRow.qml; aawc.java, aari.java:462-466,
 *   afzj.A/B): hidden until a phone ended a sync (/org/asteroidos/health/sync/supported); "Last synced" and when
 *   (aibv.w: the time today, the month and day within a year, the date before; "- -" never), "Syncing" with the
 *   button not usable, "Can't Sync Data" with "Retry"; the list's opening writes "today@<ms>" to
 *   sync/request (stock WEAR_TODAY_APP_OPEN), the button "button@<ms>" (WEAR_TODAY_SYNC_BUTTON);
 * The keys as asteroid-btsyncd writes them; the data is make-fixtures.py's invented one. Shots in /tmp/w3hlth-shots.
 */

import QtQuick
import QtTest
import Nemo.Configuration
import org.asteroid.controls
import org.asteroid.utils

import "../src/data"
import "../src/today"

Item {
    id: testRoot
    width: 384
    height: 384

    Rectangle { anchors.fill: parent; color: "black" }
    ConfigurationValue { id: supported; key: "/org/asteroidos/health/sync/supported"; defaultValue: false }
    ConfigurationValue { id: syncState; key: "/org/asteroidos/health/sync/state"; defaultValue: "idle" }
    ConfigurationValue { id: lastMs; key: "/org/asteroidos/health/sync/last-ms"; defaultValue: 0 }
    ConfigurationValue { id: request; key: "/org/asteroidos/health/sync/request"; defaultValue: "" }
    ConfigurationValue { id: use12h; key: "/org/asteroidos/settings/use-12h-format"; defaultValue: false }

    Component { id: todayComp; TodayPage { width: 384; height: 384 } }
    Component { id: rowComp; SyncRow { width: 300 } }
    property var made: null

    TestCase {
        name: "TodaySync"
        when: windowShown

        function byName(item, name) {
            if (!item)
                return null
            if (item.objectName === name)
                return item
            var lists = [item.children, item.contentItem ? item.contentItem.children : null]
            for (var k = 0; k < lists.length; k++) {
                var d = lists[k]
                for (var i = 0; d && i < d.length; i++) {
                    var r = byName(d[i], name)
                    if (r)
                        return r
                }
            }
            return null
        }
        function init() {
            supported.value = false
            syncState.value = "idle"
            lastMs.value = 0
            request.value = ""
            use12h.value = false
            wait(200)
        }
        function cleanup() {
            if (testRoot.made)
                testRoot.made.destroy()
            testRoot.made = null
            wait(0)
        }
        function shot(item, name) {
            item.grabToImage(function (r) { r.saveToFile("/tmp/w3hlth-shots/" + name + ".png") })
            wait(80)
        }
        function today() {
            testRoot.made = todayComp.createObject(testRoot)
            verify(testRoot.made)
            wait(300)
            return testRoot.made
        }
        // the list as far as it scrolls (its end above the bottom margin)
        function toEnd(page) {
            var l = page.list
            l.positionViewAtEnd()
            wait(200)
            l.contentY = l.originY + l.contentHeight + l.bottomMargin - l.height
            wait(300)
        }

        // no phone ever ended a sync here: no row, nothing asked
        function test_0_hidden() {
            var page = today()
            var keys = page.rows.map(function(r) { return r.type })
            compare(keys[keys.length - 1], "settings")
            compare(request.value, "")
            verify(!byName(page, "syncRow"))
        }

        function test_1_lastSynced() {
            supported.value = true
            var at = new Date()
            at.setMinutes(at.getMinutes() - 5)
            lastMs.value = at.getTime()
            wait(200)
            var before = Date.now()
            var page = today()
            var r = page.rows
            compare(r[r.length - 1].type, "sync")
            compare(r[r.length - 2].type, "settings")
            // the opening asked for a sync
            var parts = String(request.value).split("@")
            compare(parts[0], "today")
            verify(Number(parts[1]) >= before)
            toEnd(page)
            var row = byName(page, "syncRow")
            verify(row)
            var text = byName(row, "syncText")
            // a time today in the 24-hour format
            compare(text.text, "Last synced\n " + TimeFormat.time(at))
            var button = byName(row, "syncButton")
            compare(button.text, "Sync")
            verify(button.enabled)
            shot(testRoot, "sync-last-synced")
            // the button
            mouseClick(button)
            wait(200)
            compare(String(request.value).split("@")[0], "button")
        }

        function test_2_syncingAndFailed() {
            supported.value = true
            lastMs.value = 0
            syncState.value = "syncing"
            wait(200)
            var page = today()
            toEnd(page)
            var row = byName(page, "syncRow")
            compare(byName(row, "syncText").text, "Syncing")
            verify(!byName(row, "syncButton").enabled)
            shot(testRoot, "sync-syncing")
            syncState.value = "failed"
            wait(200)
            compare(byName(row, "syncText").text, "Can't Sync Data")
            compare(byName(row, "syncButton").text, "Retry")
            verify(byName(row, "syncButton").enabled)
            shot(testRoot, "sync-failed")
            syncState.value = "idle"
            wait(200)
            // never synced
            compare(byName(row, "syncText").text, "Last synced\n - -")
        }

        function test_3_when() {
            testRoot.made = rowComp.createObject(testRoot)
            var row = testRoot.made
            var now = new Date(2026, 10, 25, 15, 0)
            compare(row.whenText(0, now), "- -")
            compare(row.whenText(new Date(2026, 10, 25, 7, 30).getTime(), now), TimeFormat.time(new Date(2026, 10, 25, 7, 30)))
            // the month and day in the locale's order (en_GB: the day first)
            var y = row.whenText(new Date(2026, 10, 24, 22, 0).getTime(), now)
            var dayFirst = Qt.locale().dateFormat(Locale.LongFormat).search(/d/) < Qt.locale().dateFormat(Locale.LongFormat).search(/M/)
            compare(y, dayFirst ? "24 November" : "November 24")
            // more than a year: the short date
            var old = new Date(2025, 5, 2, 9, 0)
            compare(row.whenText(old.getTime(), now), Qt.locale().toString(old, Qt.locale().dateFormat(Locale.ShortFormat)))
        }
    }
}
