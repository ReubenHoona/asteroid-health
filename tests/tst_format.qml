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

    // R5 E-10: the Morning Brief's order, its Today card's morning, the outro's line of the day
    function test_morningBrief() {
        compare(F.MORNING_PAGES.join(" "), "landing sleep exercise weather outro")
        verify(!F.morningCardShown(new Date(2026, 10, 25, 3, 59)))
        verify(F.morningCardShown(new Date(2026, 10, 25, 4, 0)))
        verify(F.morningCardShown(new Date(2026, 10, 25, 11, 59)))
        verify(!F.morningCardShown(new Date(2026, 10, 25, 12, 0)))
        compare(F.outroLine(new Date(2026, 0, 1, 8, 0)), 0)
        compare(F.outroLine(new Date(2026, 0, 2, 23, 0)), 1)
        compare(F.outroLine(new Date(2026, 0, 6, 7, 0)), 0)
        // a day keeps its line whatever the hour
        compare(F.outroLine(new Date(2026, 10, 25, 0, 1)), F.outroLine(new Date(2026, 10, 25, 23, 59)))
        compare(HealthText.outroText(new Date(2026, 0, 1)), "Your progress starts today. Let’s go!")
        compare(HealthText.outroText(new Date(2026, 0, 5)), "It’s a new day—Let’s make well-being your top task.")
    }

    // R5 E-09: the cardio load's target and state words
    function test_cardioTexts() {
        compare(HealthText.cardioTargetText({ hasTarget: true, low: 32, high: 52, daysLeft: 0 }), "Target 32–52")
        compare(HealthText.cardioTargetText({ hasTarget: false, daysLeft: 5 }), "See target load in 5 days")
        compare(HealthText.cardioTargetText({ hasTarget: false, daysLeft: 1 }), "See target load in 1 day")
        compare(HealthText.cardioTargetText(null), "")
        compare(HealthText.cardioStateText({ state: "in" }), "In target")
        compare(HealthText.cardioStateText({ state: "above" }), "Above target")
        compare(HealthText.cardioStateText({ state: "below" }), "Below target")
        compare(HealthText.cardioStateText({ state: "" }), "")
    }

    // R5 E-18: the main goal of another type than steps (stock's PrimaryGoalType)
    function test_mainGoal() {
        compare(F.goalType("floors"), "floors")
        compare(F.goalType("sleep"), "steps")
        compare(F.goalType(undefined), "steps")
        var s = { energyKcal: 1234.4, distanceM: 3520, floors: 7, azm: 12 }
        compare(F.goalValue("steps", s, 6240), 6240)
        compare(F.goalValue("calories", s, 6240), 1234.4)
        compare(F.goalValue("distance", s, 6240), 3520)
        compare(F.goalValue("floors", s, 6240), 7)
        compare(F.goalValue("azm", s, 6240), 12)
        compare(F.goalValue("azm", {}, 6240), 0)
        compare(F.goalCardKey("calories"), "energy")
        compare(F.goalCardKey("azm"), "azm")
        compare(F.goalCardKey("x"), "steps")
        compare(F.goalIcon("floors"), "eos-health-floors")
        compare(F.goalIcon("calories"), "eos-health-energy")
        compare(HealthText.goalText(7, 10, "floors"), "3 left")
        compare(HealthText.goalText(1234.4, 2000, "calories"), "766 left")
        // a distance in the locale's unit, compared in tens of metres
        compare(HealthText.goalText(3520, 8047, "distance"), HealthText.distanceText(4530) + " left")
        compare(HealthText.goalText(8050, 8047, "distance"), "Goal met")
        compare(HealthText.goalText(9050, 8047, "distance"), HealthText.distanceText(1000) + " over goal")
        compare(HealthText.goalValueText("distance", 3520), HealthText.distanceText(3520))
        compare(HealthText.goalValueText("calories", 1234.4), "1,234")
        compare(HealthText.goalValueText("steps", 6240), "6,240")
        compare(HealthText.goalCaption("azm"), "Active Zone Minutes")
        compare(HealthText.goalCaption("calories"), "Energy burned")
        compare(HealthText.goalCaption(undefined), "Steps")
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

    // M4 WO-13: the skin temperature variation's numbers and words
    function test_skinTemp() {
        compare(F.skinTempDelta(0.31, false), 0.3)
        compare(F.skinTempDelta(-0.26, false), -0.3)
        compare(F.skinTempDelta(0.5, true), 0.9)
        compare(F.skinTempDelta(-1.14, true), -2.1)
        compare(HealthText.skinTempValueText(0.31, false), "0.3°C")
        compare(HealthText.skinTempValueText(-0.26, true), "-0.5°F")
        compare(F.skinTempHasValue("inRange"), true)
        compare(F.skinTempHasValue("calibrating"), false)
        compare(F.skinTempIcon("aboveRange"), "eos-health-skintemp-up")
        compare(F.skinTempIcon("belowRange"), "eos-health-skintemp-down")
        compare(F.skinTempIcon("tracking"), "eos-health-skintemp")
        var week = [{ hasVariation: false }, { hasVariation: true, devC: 0.1, loC: -0.5, hiC: 0.5, state: "inRange" },
                    { hasVariation: true, devC: 1.14, loC: -0.5, hiC: 0.5, state: "aboveRange" }]
        compare(F.skinTempInRange(week).inRange, 1)
        compare(F.skinTempInRange(week).total, 2)
        compare(F.skinTempTicks(week, false), [-2, 0, 2])
        compare(F.skinTempTicks([{ hasVariation: true, devC: 0.2, loC: -0.6, hiC: 0.6 }], false), [-1, 0, 1])
        compare(F.skinTempTicks(week, true), [-3, 0, 3])
        compare(F.skinTempTicks([], false), [-1, 0, 1])
        compare(HealthText.skinTempStateText({ state: "inRange" }), "In range")
        compare(HealthText.skinTempStateText({ state: "aboveRange" }), "Above range")
        compare(HealthText.skinTempStateText({ state: "belowRange" }), "Below range")
        compare(HealthText.skinTempStateText({ state: "calibrating", nightsLeft: 3 }), "Wear to sleep 3 more times")
        compare(HealthText.skinTempStateText({ state: "calibrating", nightsLeft: 1 }), "Wear to sleep one more time")
        compare(HealthText.skinTempStateText({ state: "tracking" }), "Tracking…")
        compare(HealthText.skinTempStateText({ state: "analyzing" }), "Analyzing…")
        compare(HealthText.skinTempStateText({ state: "noData" }), "Wear your watch to sleep")
        compare(HealthText.skinTempStateText(undefined), "Wear your watch to sleep")
        compare(HealthText.skinTempExplanation("calibrating"),
                "Skin temperature variation is the fluctuation in temperature taken from your wrist while you sleep")
        compare(HealthText.skinTempExplanation("aboveRange"), "May be associated with warmer surroundings or other factors")
        compare(HealthText.skinTempExplanation("belowRange"), "May be associated with cooler surroundings or other factors")
        compare(HealthText.skinTempExplanation("inRange"), "")
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
