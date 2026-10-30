/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The image's sensorlogd loaders on the fixtures of make-fixtures.py (HOME),
 * through HealthStats.js: malformed lines, a missing day, a single reading.
 */

import QtQuick
import QtTest

import org.asteroid.sensorlogd

import "../src/data/HealthStats.js" as S

TestCase {
    name: "HealthData"

    HrDataLoader { id: hr }
    StepsDataLoader { id: steps }

    function test_malformedFile() {
        var j = new Date(2026, 0, 15, 12)
        var raw = hr.getDataForDate(j)
        // 64, 65.5, 0 and 66 parse; the rest of the lines are skipped
        compare(raw.length, 4)
        var r = S.heartRateDay(raw, j, 48)
        compare(r.count, 3)
        compare(r.min, 64)
        compare(r.max, 66)
        compare(r.latest, 66)
        compare(r.latestTime, S.dayStart(j) + 12 * 3600 + 3000)
        compare(r.resting, -1)
    }

    function test_stepsFile() {
        var j = new Date(2026, 0, 15, 12)
        var s = S.stepsDay(steps.getDataForDate(j), j)
        compare(s.count, 4)
        compare(s.total, 900)
        compare(steps.getTotalForDate(j), 900)
        compare(s.hours[12], 100)
        compare(s.hours[13], 150)
        compare(s.hours[14], 0)
        compare(s.hours[15], 650)
    }

    function test_missingDay() {
        var missing = S.addDays(new Date(), -2)
        compare(hr.getDataForDate(missing).length, 0)
        compare(S.heartRateDay(hr.getDataForDate(missing), missing, 48).count, 0)
        compare(steps.getTotalForDate(missing), 0)
        compare(S.stepsDay(steps.getDataForDate(missing), missing).count, 0)
    }

    function test_singleReading() {
        var d = S.addDays(new Date(), -4)
        var r = S.heartRateDay(hr.getDataForDate(d), d, 48)
        compare(r.count, 1)
        compare(r.latest, 77)
        compare(r.min, 77)
        compare(r.max, 77)
        compare(r.resting, -1)
        compare(new Date(r.latestTime * 1000).getHours(), 9)
    }

    function test_malformedDay() {
        // today-3: 5 bad lines in front, 10:00-18:00 every 10 minutes, a torn line
        var d = S.addDays(new Date(), -3)
        var r = S.heartRateDay(hr.getDataForDate(d), d, 48)
        compare(r.count, 48)
        verify(r.resting > 0)
        verify(r.min <= r.resting && r.resting <= r.max)
        compare(r.buckets.filter(function(b) { return b !== null }).length, 16)
    }

    function test_today() {
        var d = new Date()
        var r = S.heartRateDay(hr.getDataForDate(d), d, 48)
        verify(r.count > 0)
        compare(r.latest, 100)
        // written 5 minutes before the fixtures were made, just before the run
        var m = S.minutesAgo(r.latestTime, Date.now() / 1000)
        verify(m >= 5 && m <= 8, "minutes ago " + m)
    }
}
