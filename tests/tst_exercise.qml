/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * M4 WO-10: the Exercise days card of the Today list and its page (src/exercise/ExerciseDaysPage.qml; stock
 * TodayRoute.Details("EXERCISE"): ExerciseDetailsViewModel, xny.java) on make-fixtures.py's invented workouts in
 * health.db, read through sensorlogd's WorkoutLoader, on a fixed clock: FT=1795618800 (Wednesday 25 November 2026,
 * 15:00 in a fictional zone without offset; the fixtures made for that moment). This week (from Monday 23): the Run of today 07:00
 * (40 min, 5.2 km) and the Bike of yesterday 18:00 (45 min); not counted: the Walk of Friday 20 (the week before),
 * the deleted Yoga of Sunday 22 and the Hike still on since 14:00. 2 of 3 days; the week's totals of the two.
 * Shots in /tmp/w3hlth-shots.
 */

import QtQuick
import QtTest
import Nemo.Configuration
import org.asteroid.controls

import "../src/data"
import "../src/data/HealthFormat.js" as Format
import "../src/today"
import "../src/exercise"

Item {
    id: testRoot
    width: 384
    height: 384

    Rectangle { anchors.fill: parent; color: "black" }
    ConfigurationValue { id: use12h; key: "/org/asteroidos/settings/use-12h-format"; defaultValue: true }

    Component { id: todayComp; TodayPage { width: 384; height: 384 } }
    Component { id: pageComp; ExerciseDaysPage { width: 384; height: 384 } }
    property var made: null

    TestCase {
        name: "ExerciseDays"
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
        function at(d, h, m) { return new Date(2026, 10, d, h, m || 0).getTime() }

        function test_0_clock() {
            // the fake clock and the fixtures agree
            var now = new Date()
            compare(now.getFullYear(), 2026)
            compare(now.getMonth(), 10)
            compare(now.getDate(), 25)
            compare(now.getHours(), 15)
            HealthData.refresh()
            compare(HealthData.today.getDate(), 25)
        }

        function test_1_reader() {
            var list = HealthData.weekWorkouts(HealthData.today)
            // health.db's rows of Monday 23 to today, newest first: the Hike still on, the Run, the Bike
            compare(list.map(function (w) { return w.type }), ["Hike", "Run", "Bike"])
            compare(list[0].ended, false)
            var wk = Format.exerciseWeek(list, Format.weekStartMs(HealthData.today.getTime()))
            compare(wk.done, 2)
            compare(wk.days, [false, true, true, false, false, false, false])
            compare(wk.count, 2)
            compare(wk.activeS, 85 * 60)
            compare(wk.azm, 111)
            compare(wk.kcal, 792)
            compare(wk.moderateS, 35 * 60)
            compare(wk.vigorousS, 34 * 60)
            compare(wk.peakS, 4 * 60)
            compare(Format.dayWorkouts(list, at(25, 0)).map(function (w) { return w.type }), ["Run"])
            compare(Format.weekStartMs(at(25, 15)), at(23, 0))
            compare(Format.EXERCISE_DAYS_GOAL, 3)
            // nothing: none
            var none = Format.exerciseWeek([], at(23, 0))
            compare(none.done, 0)
            compare(Format.exerciseWeek(null, at(23, 0)).done, 0)
        }

        function test_2_card() {
            testRoot.made = todayComp.createObject(testRoot)
            var rows = testRoot.made.rows
            var keys = rows.map(function (r) { return r.type + ":" + r.key })
            // stock's stat 6 (EXERCISE), after Active Zone Minutes
            compare(keys.indexOf("card:exercise"), keys.indexOf("card:azm") + 1)
            var r = rows[keys.indexOf("card:exercise")]
            compare(r.title, "Exercise days")
            compare(r.value, "2")
            compare(r.subtitle, "2 of 3 days this week")
            compare(r.icon, "eos-exercise")
            compare(r.category, "fitness")
        }

        function test_3_page() {
            use12h.value = true
            testRoot.made = pageComp.createObject(testRoot)
            var made = testRoot.made
            wait(100)
            compare(made.title, "Exercise days")
            compare(byName(made, "exerciseDaysWeek").value, "2 of 3")
            for (var i = 0; i < 7; i++)
                compare(byName(made, "exerciseDay" + i).done, i === 1 || i === 2, "day " + i)
            // today: the Run, its start in the watch's format and its active time
            compare(byName(made, "exerciseToday0").caption, "Run · " + TimeFormat.time(new Date(at(25, 7))))
            compare(byName(made, "exerciseToday0").value, "40 min")
            compare(byName(made, "exerciseToday1"), null)
            // the week
            compare(byName(made, "exerciseTotalTime").value, "1 hr 25 min")
            compare(byName(made, "exerciseAzm").value, "111")
            compare(byName(made, "exerciseCalories").value, "792")
            compare(byName(made, "exerciseCalories").unit, "Cal")
            compare(byName(made, "exerciseModerate").value, "35 min")
            compare(byName(made, "exerciseVigorous").value, "34 min")
            compare(byName(made, "exercisePeak").value, "4 min")
            shot(made, "exercise-days-top")
            made.flickable.contentY = 260
            wait(100)
            shot(made, "exercise-days-week")
            made.flickable.contentY = made.flickable.contentHeight - made.height
            wait(100)
            shot(made, "exercise-days-end")
        }
    }
}
