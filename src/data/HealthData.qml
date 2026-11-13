/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma Singleton

import QtQuick
import org.asteroid.sensorlogd

import "HealthStats.js" as Stats

/*
 * The data of every Health page, read once and shared: the day summaries of sensorlogd's
 * HealthMetricsLoader (steps, distance, energy, floors, zones, Active Zone Minutes, hourly
 * activity), last night's sleep, the heart rate readings of a day and the settings
 * (LoggerSettings: the one steps goal and the Health features).
 *
 * Nothing here runs on a timer. The loaders watch the day files and emit dataChanged() when
 * the daemon writes (a batch of the sensor hub, so a few times an hour at most); pages read
 * again then, and when the app comes to the front (the date may have moved on).
 */
QtObject {
    id: data

    // counts up whenever the files change or the app returns: a binding on it re-reads
    property int version: 0
    // today, as of the last version
    property date today: new Date()

    readonly property alias settings: logger
    readonly property alias metrics: metricsLoader
    readonly property alias stepsLoader: steps
    // the one steps goal (health-fitness-10): /org/asteroidos/ux/steps-goal, 10000
    readonly property int stepGoal: Math.max(1, logger.stepGoalTarget)

    // what was read, by day (plain objects: filling the cache while a page's binding is evaluated must
    // not count as a change)
    readonly property var _store: ({ days: {}, hr: {}, sleep: null })

    property LoggerSettings _logger: LoggerSettings { id: logger }
    property HealthMetricsLoader _metrics: HealthMetricsLoader {
        id: metricsLoader
        onDataChanged: data.touch()
    }
    property SleepDataLoader _sleepLoader: SleepDataLoader {
        id: sleepLoader
        onDataChanged: data.touch()
    }
    property StepsDataLoader _steps: StepsDataLoader {
        id: steps
        onDataChanged: data.touch()
        onTodayTotalChanged: data.touch()
    }
    property HrDataLoader _hrLoader: HrDataLoader {
        id: hrLoader
        onDataChanged: data.touch()
    }
    property Connections _app: Connections {
        target: Qt.application
        function onActiveChanged() {
            if (Qt.application.active) {
                data.refresh()
                steps.triggerDaemonRecording()
            }
        }
    }

    Component.onCompleted: steps.triggerDaemonRecording()

    // the files changed: forget what was read of today and yesterday (a day file of an earlier
    // day is no longer written), and tell the pages once
    function touch() {
        Qt.callLater(refresh)
    }

    function refresh() {
        var t = new Date()
        var keep = {}
        var hrKeep = {}
        for (var k in _store.days)
            if (Stats.daysBetween(_store.days[k].date, t) > 1)
                keep[k] = _store.days[k]
        for (var h in _store.hr)
            if (Stats.daysBetween(_store.hr[h].date, t) > 1)
                hrKeep[h] = _store.hr[h]
        _store.days = keep
        _store.hr = hrKeep
        _store.sleep = null
        today = t
        version++
    }

    // the HealthMetricsLoader summary of a day, cached until the files change
    function summary(date) {
        var key = Stats.dayKey(date)
        if (_store.days[key] === undefined)
            _store.days[key] = { date: Stats.addDays(date, 0), value: metricsLoader.summary(Stats.addDays(date, 0)) }
        return _store.days[key].value
    }

    // the steps of a day; today's count may be ahead of the log (the sensor's live count)
    function stepsOf(date) {
        var s = summary(date).steps || 0
        return Stats.daysBetween(date, today) === 0 ? Math.max(s, steps.todayTotal) : s
    }

    // the heart rate summary of a day (HealthStats.heartRateDay of the day file), cached
    function heartDay(date) {
        var key = Stats.dayKey(date)
        if (_store.hr[key] === undefined) {
            var raw = hrLoader.getDataForDate(Stats.addDays(date, 0))
            _store.hr[key] = { date: Stats.addDays(date, 0), value: Stats.heartRateDay(raw, date, 48), points: raw }
        }
        return _store.hr[key].value
    }

    // the readings of a day as [{t, v}] (seconds, bpm)
    function heartPoints(date) {
        heartDay(date)
        return Stats.heartRates(_store.hr[Stats.dayKey(date)].points, Stats.dayStart(date), Stats.dayEnd(date))
    }

    // the night that ended today (or yesterday, if none today): SleepDataLoader.lastNight()
    function sleep() {
        if (_store.sleep === null)
            _store.sleep = sleepLoader.lastNight()
        return _store.sleep
    }

    // the Active Zone Minutes of the week (Monday to `date`), as HealthMetricsLoader.azmWeek, from
    // the cached summaries
    function azmWeek(date) {
        var total = 0
        var dow = (date.getDay() + 6) % 7
        for (var i = dow; i >= 0; i--)
            total += summary(Stats.addDays(date, -i)).azm || 0
        return total
    }

    // the last seven days ending on `end` (a Date): [{date, summary}]
    function week(end) {
        var out = []
        for (var i = 6; i >= 0; i--) {
            var d = Stats.addDays(end, -i)
            out.push({ date: d, summary: summary(d) })
        }
        return out
    }
}
