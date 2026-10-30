/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The day summaries of HealthStats.js. Run with TZ set to a zone with
 * daylight saving on the last Sundays of March and October (the runner sets
 * the fictional "AAA0BBB,M3.5.0/1,M10.5.0"): test_dstDays checks for it.
 */

import QtQuick
import QtTest

import "../src/data/HealthStats.js" as S

TestCase {
    name: "HealthStats"

    // a local day of the test zone, at noon
    function day(y, m, d) { return new Date(y, m - 1, d, 12) }
    function at(y, m, d, h, min) { return new Date(y, m - 1, d, h, min || 0).getTime() / 1000 }
    function pt(t, v) { return Qt.point(t, v) }

    function test_restingSparse() {
        // one reading every 10 minutes: 3 in each 30 minutes
        var data = []
        var values = [70, 64, 58, 56, 57, 60, 72, 90, 88, 75]
        for (var i = 0; i < values.length; i++)
            data.push(pt(at(2026, 10, 20, 3, 0) + i * 600, values[i]))
        var r = S.heartRateDay(data, day(2026, 10, 20), 48)
        compare(r.count, 10)
        compare(r.min, 56)
        compare(r.max, 90)
        // lowest 30 minute stretch: 58, 56, 57
        compare(r.resting, 57)
        compare(r.latest, 75)
        compare(r.latestTime, at(2026, 10, 20, 4, 30))
    }

    function test_restingDenseExercise() {
        // a calm hour every 10 minutes, then a minute by minute workout
        var data = []
        for (var i = 0; i < 6; i++)
            data.push(pt(at(2026, 10, 20, 8, 0) + i * 600, 62 + (i % 2)))
        for (var j = 0; j < 40; j++)
            data.push(pt(at(2026, 10, 20, 18, 0) + j * 60, 120 + j))
        var r = S.heartRateDay(data, day(2026, 10, 20), 48)
        compare(r.resting, 62)   // (62 + 63 + 62) / 3 = 62.3
        compare(r.max, 159)
    }

    function test_restingTooFew() {
        // two readings in any 30 minutes: no resting rate
        var data = [pt(at(2026, 10, 20, 9, 0), 60), pt(at(2026, 10, 20, 9, 20), 61),
                    pt(at(2026, 10, 20, 11, 0), 80), pt(at(2026, 10, 20, 13, 0), 82)]
        var r = S.heartRateDay(data, day(2026, 10, 20), 48)
        compare(r.count, 4)
        compare(r.resting, -1)
        compare(r.min, 60)
        compare(r.max, 82)
    }

    function test_singleReading() {
        var r = S.heartRateDay([pt(at(2026, 10, 20, 14, 29), 100)], day(2026, 10, 20), 48)
        compare(r.count, 1)
        compare(r.min, 100)
        compare(r.max, 100)
        compare(r.latest, 100)
        compare(r.resting, -1)
        compare(r.latestBucket, 28)
        compare(r.buckets[28].lo, 100)
        compare(r.buckets[28].hi, 100)
        compare(r.buckets.filter(function(b) { return b !== null }).length, 1)
    }

    function test_missingDay() {
        var lists = [[], null, undefined]
        for (var i = 0; i < lists.length; i++) {
            var r = S.heartRateDay(lists[i], day(2026, 10, 20), 48)
            compare(r.count, 0)
            compare(r.latest, 0)
            compare(r.resting, -1)
            compare(r.latestBucket, -1)
            compare(r.buckets.length, 48)
            compare(r.buckets.filter(function(b) { return b !== null }).length, 0)
            var s = S.stepsDay(lists[i], day(2026, 10, 20))
            compare(s.count, 0)
            compare(s.total, 0)
            compare(s.hours.length, 24)
        }
    }

    function test_malformedRecords() {
        var t = at(2026, 10, 20, 10, 0)
        var data = [
            null,
            { x: NaN, y: 70 },
            { x: t, y: NaN },
            { x: "abc", y: 70 },
            pt(t + 60, 0),        // off the wrist
            pt(t + 120, 300),     // no wrist reading
            pt(t + 180, -5),
            pt(t + 240, 24),
            pt(t + 300, 72),
            pt(t + 360, 251),
            pt(t + 420, 250)
        ]
        var r = S.heartRateDay(data, day(2026, 10, 20), 48)
        compare(r.count, 2)
        compare(r.min, 72)
        compare(r.max, 250)
        compare(r.latest, 250)
    }

    function test_unsorted() {
        var data = [pt(at(2026, 10, 20, 12, 0), 80), pt(at(2026, 10, 20, 18, 0), 95), pt(at(2026, 10, 20, 6, 0), 55)]
        var r = S.heartRateDay(data, day(2026, 10, 20), 48)
        compare(r.latest, 95)
        compare(r.latestTime, at(2026, 10, 20, 18, 0))
        compare(r.latestBucket, 36)
    }

    function test_dayBoundaries() {
        var d = day(2026, 10, 20)
        var start = S.dayStart(d)
        var end = S.dayEnd(d)
        compare(start, at(2026, 10, 20, 0, 0))
        compare(end, at(2026, 10, 21, 0, 0))
        var data = [pt(start - 1, 61), pt(start, 62), pt(end - 1, 63), pt(end, 64)]
        var r = S.heartRateDay(data, d, 48)
        compare(r.count, 2)
        compare(r.min, 62)
        compare(r.max, 63)
        compare(r.latestBucket, 47)
        verify(r.buckets[0] !== null)
        // any time of the day is the same day
        compare(S.dayStart(new Date(2026, 9, 20, 0, 0, 0)), start)
        compare(S.dayStart(new Date(2026, 9, 20, 23, 59, 59)), start)
    }

    function test_dstDays() {
        // the zone is one hour ahead of UTC in summer (AAA0BBB)
        var autumn = day(2026, 10, 25)   // last Sunday of October: 25 hours
        compare(S.dayStart(autumn), Date.UTC(2026, 9, 24, 23) / 1000)
        compare(S.dayEnd(autumn) - S.dayStart(autumn), 25 * 3600)
        compare(S.hourFraction(autumn, 12), 13 / 25)
        var spring = day(2026, 3, 29)    // last Sunday of March: 23 hours
        compare(S.dayEnd(spring) - S.dayStart(spring), 23 * 3600)
        compare(S.hourFraction(spring, 6), 5 / 23)
        // the last half hour of the long day is the last bucket
        var r = S.heartRateDay([pt(S.dayEnd(autumn) - 900, 70)], autumn, 48)
        compare(r.latestBucket, 47)
        compare(S.daysBetween(day(2026, 10, 24), day(2026, 10, 26)), 2)
        compare(S.daysBetween(day(2026, 3, 28), day(2026, 3, 30)), 2)
        compare(S.dayKey(S.addDays(day(2026, 10, 24), 1)), "2026-10-25")
        compare(S.dayKey(S.addDays(day(2026, 10, 25), 1)), "2026-10-26")
    }

    function test_dayKind() {
        var today = day(2026, 10, 30)
        compare(S.dayKind(new Date(2026, 9, 30, 0, 1), today), 0)
        compare(S.dayKind(new Date(2026, 9, 29, 23, 59), today), 1)
        compare(S.dayKind(day(2026, 10, 24), today), 6)
        compare(S.dayKind(day(2026, 10, 23), today), 7)
        compare(S.dayKind(day(2026, 10, 31), today), -1)
        compare(S.dayKind(day(2025, 12, 31), day(2026, 1, 1)), 1)
        compare(S.dayKey(day(2026, 1, 5)), "2026-01-05")
    }

    function test_stepsHours() {
        var d = day(2026, 10, 20)
        var data = [
            pt(at(2026, 10, 20, 7, 10), 300),
            pt(at(2026, 10, 20, 7, 50), 900),
            pt(at(2026, 10, 20, 9, 5), 1500),
            pt(at(2026, 10, 20, 12, 0), 1400),   // a counter restart: nothing
            pt(at(2026, 10, 20, 12, 30), -1),    // no count
            pt(at(2026, 10, 20, 13, 0), 2000),
            pt(at(2026, 10, 21, 0, 0, 30), 2300) // the day's total, written after midnight
        ]
        var s = S.stepsDay(data, d)
        compare(s.count, 6)
        compare(s.total, 2300)
        compare(s.hours[7], 900)
        compare(s.hours[9], 600)
        compare(s.hours[12], 0)
        compare(s.hours[13], 500)
        compare(s.hours[23], 300)
        compare(s.hours.reduce(function(a, b) { return a + b }, 0), 2300)
    }

    function test_axes() {
        var a = S.heartRateAxis(58, 124)
        compare(a.ticks.length, 3)
        verify(a.lo <= 58 && a.hi >= 124)
        compare(a.ticks[0] % 10, 0)
        compare(a.ticks[1] - a.ticks[0], a.ticks[2] - a.ticks[1])
        var calm = S.heartRateAxis(60, 64)
        verify(calm.hi - calm.lo >= 40)
        verify(calm.lo <= 60 && calm.hi >= 64)
        var one = S.heartRateAxis(100, 100)
        verify(one.lo <= 100 && one.hi >= 100 && one.hi > one.lo)
        var steps = S.stepsAxis(1234)
        compare(steps.ticks[0], 0)
        verify(steps.hi >= 1234)
        var week = S.stepsAxis(10000)
        compare(week.hi, 10000)
        compare(S.stepsAxis(0).ticks.length, 3)
        compare(S.shortNumber(5000), "5k")
        compare(S.shortNumber(1250), "1.3k")
        compare(S.shortNumber(600), "600")
    }

    function test_minutesAgo() {
        compare(S.minutesAgo(1000, 1000 + 59), 0)
        compare(S.minutesAgo(1000, 1000 + 300), 5)
        compare(S.minutesAgo(1000, 900), -1)
    }
}
