/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * HealthFormat.js and the wording of HealthText: stock's numbers and texts, with no screen.
 */

import QtQuick
import QtTest

import "../src/data"
import "../src/data/HealthStats.js" as Stats
import "../src/data/HealthFormat.js" as F

TestCase {
    name: "HealthFormat"

    function test_goalState() {
        compare(F.goalState(6240, 10000).state, "left")
        compare(F.goalState(6240, 10000).amount, 3760)
        compare(F.goalState(10000, 10000).state, "met")
        compare(F.goalState(10120, 10000).state, "over")
        compare(F.goalState(10120, 10000).amount, 120)
        compare(F.goalState(-5, 10000).amount, 10000)
        compare(F.goalFraction(5000, 10000), 0.5)
        compare(F.goalFraction(15000, 10000), 1)
        compare(F.goalFraction(0, 0), 0)
    }

    function test_goalText() {
        compare(HealthText.goalText(6240, 10000), "3,760 left")
        compare(HealthText.goalText(10000, 10000), "Goal met")
        compare(HealthText.goalText(10120, 10000), "120 over goal")
    }

    function test_hourly() {
        compare(F.hourlyState(3, 9).state, "progress")
        compare(F.hourlyState(9, 9).state, "done")
        compare(F.hourlyState(0, 0).state, "progress")
        compare(HealthText.hourlyText(3, 9), "3 of 9 hr")
        compare(HealthText.hourlyText(9, 9), "Completed today")
    }

    function test_distance() {
        compare(F.distance(3520, false).unit, "km")
        compare(F.distance(3520, false).value, 3.52)
        compare(F.distance(1609.344, true).unit, "mi")
        compare(F.distance(1609.344, true).value, 1)
        compare(F.distance(-4, false).value, 0)
        compare(F.distanceText(3520, false, Qt.locale("en_GB")), "3.52 km")
        compare(F.distanceText(8046.72, true, Qt.locale("en_US")), "5.00 mi")
    }

    function test_energy() {
        compare(F.energyValue(1492.4), 1492)
        compare(F.energyValue(1492.5), 1493)
        compare(F.energyValue(undefined), 0)
    }

    function days(list) {
        return list.map(function(v, i) { return { date: new Date(2026, 10, 7 + i, 12), summary: v } })
    }

    function hours(at, steps) {
        var h = []
        for (var i = 0; i < 24; i++)
            h.push(i === at ? steps : 0)
        return h
    }

    function test_bestDayAndHour() {
        var d = days([{ steps: 4100, distanceM: 2900, hourSteps: hours(9, 1500) },
                      { steps: 12034, distanceM: 8470, hourSteps: hours(18, 2400) },
                      { steps: 0, distanceM: 0, hourSteps: hours(0, 0) },
                      { steps: 6500, distanceM: 4600, hourSteps: hours(12, 900) }])
        var b = F.best(d)
        compare(b.day.steps, 12034)
        compare(b.day.date.getDate(), 8)
        compare(b.day.distanceM, 8470)
        compare(b.hour.steps, 2400)
        compare(b.hour.hour, 18)
        compare(b.hour.date.getDate(), 8)
        // the hour's distance: the day's, in proportion
        verify(Math.abs(b.hour.distanceM - 8470 * 2400 / 12034) < 1e-6)
        compare(F.averageSteps(d), Math.round((4100 + 12034 + 6500) / 3))
        // a tie goes to the later day
        var t = F.best(days([{ steps: 500, distanceM: 1, hourSteps: hours(8, 500) }, { steps: 500, distanceM: 1, hourSteps: hours(9, 500) }]))
        compare(t.day.date.getDate(), 8)
        compare(t.hour.hour, 9)
        // nothing walked: no best day, no best hour ('No best hour value'), no average
        var none = F.best(days([{ steps: 0, hourSteps: hours(0, 0) }, {}]))
        compare(none.day, null)
        compare(none.hour, null)
        compare(F.averageSteps(days([{ steps: 0 }])), -1)
        compare(F.best([]).day, null)
    }

    function test_range() {
        compare(F.range(58, 112, 40).has, true)
        compare(F.range(58, 112, 40).low, "58")
        compare(F.range(58, 112, 40).high, "112")
        compare(F.range(0, 0, 0).has, false)
        compare(F.range(0, 0, 0).low, "- -")
        compare(HealthText.none, "- -")
    }

    function test_zones() {
        var z = F.zoneMinutes({ zoneLight: 86, zoneModerate: 11, zoneVigorous: 30, zonePeak: 2 })
        compare(z.total, 129)
        compare(F.zoneMinutes(null).total, 0)
    }

    function test_minuteMeans() {
        var m = F.minuteMeans([{ t: 600, v: 60 }, { t: 630, v: 70 }, { t: 700, v: 80 }, { t: 3600, v: 90 }])
        compare(m.length, 3)
        compare(m[0].t, 600)
        compare(m[0].v, 65)
        compare(m[1].t, 660)
        compare(m[1].v, 80)
        compare(m[2].v, 90)
        compare(F.minuteMeans([]).length, 0)
    }

    function test_restingAverage() {
        compare(F.restingAverage([{ resting: 52 }, { resting: -1 }, { resting: 55 }]), 54)
        compare(F.restingAverage([{ resting: -1 }]), -1)
    }

    function test_durations() {
        compare(F.hoursMinutes(432).hours, 7)
        compare(F.hoursMinutes(432).minutes, 12)
        compare(HealthText.durationText(432), "7 hr 12 min")
        compare(HealthText.durationText(420), "7 hr")
        compare(HealthText.durationText(45), "45 min")
        compare(HealthText.durationText(0), "0 min")
    }

    function test_dayText() {
        var today = new Date(2026, 10, 13, 12)
        compare(HealthText.dayText(today, today), "Today")
        compare(HealthText.dayText(new Date(2026, 10, 12, 12), today), "Yesterday")
        compare(HealthText.dayText(new Date(2026, 10, 10, 12), today), new Date(2026, 10, 10).toLocaleDateString(Qt.locale(), "dddd"))
        compare(HealthText.weekText(today, today), "Last 7 days")
        verify(HealthText.weekText(new Date(2026, 10, 9, 12), today).indexOf(" - ") > 0)
    }

    function test_age() {
        var now = Date.UTC(2026, 10, 13, 5, 0, 0)
        compare(HealthText.ageText(now / 1000 - 20, now), "Just now")
        compare(HealthText.ageText(now / 1000 - 5 * 60 - 10, now), "5 min ago")
        compare(HealthText.ageText(now / 1000 - 59 * 60, now), "59 min ago")
    }

    function test_weather() {
        compare(F.weatherIcon(800), "ios-sunny-outline")
        compare(F.weatherIcon(801), "ios-partly-sunny-outline")
        compare(F.weatherIcon(804), "ios-cloudy-outline")
        compare(F.weatherIcon(500), "ios-rainy-outline")
        compare(F.weatherIcon(511), "ios-snow-outline")
        compare(F.weatherIcon(601), "ios-snow-outline")
        compare(F.weatherIcon(211), "ios-thunderstorm-outline")
        compare(F.weatherIcon(0), "ios-alert-outline")
        compare(F.temperature(295, false), 22)
        compare(F.temperature(285, true), 54)
        compare(F.temperature(295.5, false), 23)
    }
}
