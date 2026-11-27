/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The image's sensorlogd loaders on the fixtures of make-fixtures.py (HOME),
 * through HealthStats.js: malformed lines, a missing day, a single reading;
 * the resting heart rate of a day from sensorlogd's daily rows (health.db);
 * the week's Active Zone Minutes from one read.
 */

import QtQuick
import QtTest

import org.asteroid.sensorlogd

import "../src/data"
import "../src/data/HealthStats.js" as S

TestCase {
    name: "HealthData"

    HrDataLoader { id: hr }
    StepsDataLoader { id: steps }
    HealthMetricsLoader { id: metrics }

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
        compare(new Date(r.latestTime * 1000).getHours(), 9)
    }

    function test_malformedDay() {
        // today-3: 5 bad lines in front, 10:00-18:00 every 10 minutes, a torn line
        var d = S.addDays(new Date(), -3)
        var r = S.heartRateDay(hr.getDataForDate(d), d, 48)
        compare(r.count, 48)
        compare(r.buckets.filter(function(b) { return b !== null }).length, 16)
    }

    function test_restingIsTheDailyEstimate() {
        // the fixtures' daily rows: today 52, yesterday 54, three days ago 55, five 53, six 51
        var t = new Date()
        compare(metrics.restingHrOf(t), 52)
        compare(metrics.restingHrOf(S.addDays(t, -1)), 54)
        compare(metrics.restingHrOf(S.addDays(t, -2)), -1) // not worn
        compare(metrics.restingHrOf(S.addDays(t, -4)), -1) // a single reading
        compare(metrics.restingHrOf(S.addDays(t, -6)), 51)
        // what zones and energy use: the mean of the last 7 days', (52 + 54 + 55 + 53 + 51) / 5
        compare(metrics.restingHr(), 53)
    }

    // M4 WO-13: the skin temperature variation as sensorlogd's loader reads health.db (the fixtures' nights)
    function test_skinTemp() {
        var t = new Date()
        var v = metrics.skinTemp(t)
        compare(v.state, "inRange")
        compare(v.hasVariation, true)
        compare(v.nightsLeft, 0)
        verify(Math.abs(v.devC - 0.31) < 1e-9)
        verify(Math.abs(v.hiC - 0.6) < 1e-9 && Math.abs(v.loC + 0.6) < 1e-9)
        compare(metrics.skinTemp(S.addDays(t, -1)).state, "aboveRange")
        compare(metrics.skinTemp(S.addDays(t, -5)).state, "calibrating")
        compare(metrics.skinTemp(S.addDays(t, -5)).nightsLeft, 2)
        compare(metrics.skinTemp(S.addDays(t, -6)).nightsLeft, 3)
        compare(metrics.skinTemp(S.addDays(t, -7)).state, "noData")
        // the week, the oldest first: four nights without a variation (three of the baseline, one not worn)
        var w = metrics.skinTempWeek(t)
        compare(w.length, 7)
        var states = []
        for (var i = 0; i < w.length; i++)
            states.push(w[i].hasVariation ? w[i].state : "-")
        compare(states.join(" "), "- - - inRange - aboveRange inRange")
    }

    function test_theAlertDefaultsAreStocks() {
        compare(metrics.defaultHighBpm(), 120)
        compare(metrics.defaultLowBpm(), 50)
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

    // The Today list's week of Active Zone Minutes: one read of the days since Monday (zoneDays), the
    // numbers of each day's summary
    function test_azmWeekIsOneReadOfTheDays() {
        var t = new Date()
        var dow = (t.getDay() + 6) % 7
        var days = metrics.zoneDays(S.addDays(t, -dow), t)
        compare(days.length, dow + 1)
        var sum = 0
        for (var i = 0; i <= dow; i++) {
            var s = metrics.summary(S.addDays(t, i - dow))
            compare(S.dayKey(days[i].date), S.dayKey(S.addDays(t, i - dow)))
            compare(days[i].azm, s.azm)
            compare(days[i].zoneModerate, s.zoneModerate)
            compare(days[i].zoneVigorous, s.zoneVigorous)
            sum += s.azm
        }
        compare(metrics.azmWeek(t), sum)
        compare(HealthData.azmWeek(t), sum)
        console.log("Active Zone Minutes since Monday: " + sum)
    }
}
