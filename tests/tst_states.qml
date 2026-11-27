/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The empty states (health-fitness-23): stock's wording where there is nothing to show. Run twice by
 * run-all.sh: on the fixtures "empty" (a watch with no data at all) and "stale" (today's readings end
 * three hours ago); the test reads from the data which of the two it is on.
 */

import QtQuick
import QtTest
import Nemo.Configuration
import org.asteroid.controls

import "../src/data"
import "../src/data/HealthStats.js" as Stats

Item {
    width: 384
    height: 384

    Item {
        id: screen
        width: 384
        height: 384
        clip: true
        Item { id: host; anchors.fill: parent }
    }

    ConfigurationValue { id: use12h; key: "/org/asteroidos/settings/use-12h-format"; defaultValue: true }

    TestCase {
        name: "HealthStates"
        when: windowShown

        property var app: null

        function typeName(o) {
            return String(o).replace(/_QML(TYPE)?_[0-9]+.*$/, "").replace(/\(0x.*$/, "")
        }

        function byName(item, name) {
            if (!item)
                return null
            if (item.objectName === name)
                return item
            var kids = item.children || []
            for (var i = 0; i < kids.length; i++) {
                var r = byName(kids[i], name)
                if (r)
                    return r
            }
            return null
        }

        function startApp() {
            if (app)
                app.destroy()
            var c = Qt.createComponent(Qt.resolvedUrl("../src/main.qml"))
            compare(c.status, Component.Ready, c.errorString())
            app = c.createObject(host, { width: 384, height: 384 })
            verify(app)
            wait(400)
        }

        function stack() {
            return byName(app, "pageStack")
        }

        function open(key, pageName) {
            var page = byName(app, "todayList") ? byName(app, "todayList").parent : null
            verify(page)
            app.openStat(key)
            wait(700)
            compare(typeName(stack().currentLayer), pageName)
            return stack().currentLayer
        }

        function back() {
            stack().pop(stack().currentLayer)
            wait(600)
        }

        // empty: nothing was ever logged; stale: heart rate readings, the last one over 2 hours old
        readonly property bool empty: HealthData.heartDay(HealthData.today).count === 0

        function test_0_list() {
            use12h.value = true
            wait(300)
            startApp()
            var page = byName(app, "todayList").parent
            var r = page.rows
            compare(r[0].value, empty ? "0" : r[0].value)
            // the heart rate card has no value and says why
            var hr = r[8]
            compare(hr.key, "heartrate")
            compare(hr.value, "- -")
            compare(hr.subtitle, "No recent heart rate")
            if (empty) {
                compare(r[9].value, "- -")                                  // resting heart rate
                compare(r[10].value, "- -")                                 // sleep
                compare(r[10].subtitle, "Wear your watch to sleep")
                compare(r[1].value, "0")
                compare(r[5].subtitle, "0 of 150 this week")
                compare(r[6].key, "exercise")                               // M4 WO-10: no workout yet
                compare(r[6].value, "0")
                compare(r[6].subtitle, "0 of 3 days this week")
                compare(r[7].subtitle, "0 of 9 hr")
                compare(r[11].key, "skintemp")                              // M4 WO-13: no night yet
                compare(r[11].value, "Wear your watch to sleep")
                compare(r[11].subtitle, "")
            } else {
                compare(r[11].value, "In range")                            // the stale fixture has the nights
            }
        }

        function test_1_heartRatePage() {
            var page = open("heartrate", "HeartrateDetailPage")
            compare(byName(page, "bpmValue").text, "- -")
            compare(byName(page, "hrRange").valueLabel.text, empty ? "- -" : byName(page, "hrRange").valueLabel.text)
            if (empty) {
                compare(byName(page, "bpmNote").text, "No heart rate data has been collected in the last 2 hrs.")
                compare(byName(page, "hrRange").unit, "")
                compare(byName(page, "hrDayChart").points.length, 0)
                compare(byName(page, "zoneMinutes0").text, "0 min")
                compare(byName(page, "zoneNote").text, "Heart rate zones based on age and your " + HealthData.metrics.restingHr() + " bpm RHR.")
            } else {
                // readings exist, but none in the last 2 hours
                compare(byName(page, "bpmNote").text, "No recent heart rate")
                verify(byName(page, "hrDayChart").points.length > 10)
            }
            back()
        }

        function test_2_restingPage() {
            var page = open("resting", "RestingHeartRatePage")
            if (empty) {
                compare(byName(page, "restingToday").valueLabel.text, "- -")
                compare(byName(page, "restingAverage").valueLabel.text, "- -")
                compare(byName(page, "restingToday").unit, "")
            }
            back()
        }

        function test_3_stepsPage() {
            var page = open("steps", "StepsDetailPage")
            if (empty) {
                compare(byName(page, "stepsToday").valueLabel.text, "- -")
                compare(byName(page, "stepsToday").noteLabel.text, "No data yet")
                compare(byName(page, "stepsAverage").valueLabel.text, "- -")
                compare(byName(page, "stepsBestDay").valueLabel.text, "- -")
                compare(byName(page, "stepsBestHour").valueLabel.text, "- -")
                compare(byName(page, "stepsBestHour").noteLabel.text, "No best hour value")
                compare(byName(page, "stepsDayChart").visible, false)
            }
            back()
        }

        function test_4_sleepPage() {
            if (!empty)
                skip("the stale fixture has last night's sleep")
            var page = open("sleep", "SleepDetailPage")
            compare(byName(page, "sleepDuration").valueLabel.text, "- -")
            compare(byName(page, "sleepDuration").noteLabel.text, "No data yet")
            compare(byName(page, "sleepDuration").noteBottom, "Wear your watch to sleep")
            compare(byName(page, "sleepBedtime").visible, false)
            back()
        }

        function test_5_hourlyPage() {
            if (!empty)
                skip("empty fixture only")
            var page = open("hourly", "MetricDetailPage")
            compare(byName(page, "metricToday").valueLabel.text, "0")
            compare(byName(page, "metricToday").noteLabel.text, "0 of 9 hr")
            compare(byName(page, "metricAverage").valueLabel.text, "- -")
            back()
        }

        function test_6_ageAfterAnHour() {
            // a reading more than an hour old shows the time of day, in the 12 or 24 hour format
            var t = Math.floor(Date.now() / 1000) - 3 * 3600
            use12h.value = true
            wait(300)
            verify(/^\d{1,2}:\d\d\s?(am|pm)$/i.test(HealthText.ageText(t, Date.now())), HealthText.ageText(t, Date.now()))
            use12h.value = false
            wait(300)
            verify(/^\d{1,2}:\d\d$/.test(HealthText.ageText(t, Date.now())), HealthText.ageText(t, Date.now()))
            use12h.value = true
        }
    }
}
