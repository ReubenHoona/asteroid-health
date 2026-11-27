/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma Singleton

import QtQuick
import org.asteroid.sensorlogd

import "HealthStats.js" as Stats
import "HealthFormat.js" as Format

/*
 * The data of every Health page, read once and shared: the day summaries of sensorlogd's
 * HealthMetricsLoader (steps, distance, energy, floors, zones, Active Zone Minutes, hourly
 * activity), last night's sleep, the heart rate readings of a day, the resting heart rate of a
 * day (sensorlogd's daily estimate), the workouts of a week (WorkoutLoader: health.db), the skin
 * temperature variation of a morning and its week (HealthMetricsLoader: health.db) and the
 * settings (LoggerSettings: the one steps goal and the Health features).
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
    // the sleep goal, minutes a night (sensorlogd's profile: /org/asteroidos/ux/sleep-goal, 60 to 1440, else 480; the
    // phone sets it, M4 WO-11); a change is a profile change (version)
    readonly property int sleepGoalMin: { version; return metricsLoader.sleepGoal() }
    // the goal a night is measured against: its own as stored (the goal of the night it was estimated with), else
    // the one in force
    function sleepGoalOf(night) {
        return night && night.valid && Number(night.goalMin) > 0 ? Number(night.goalMin) : sleepGoalMin
    }

    // what was read, by day (plain objects: filling the cache while a page's binding is evaluated must
    // not count as a change)
    readonly property var _store: ({ days: {}, hr: {}, resting: {}, sleep: null, workouts: {}, skin: {}, skinWeek: {},
                                     zoneWeek: {}, inactive: {}, cardio: {} })

    property LoggerSettings _logger: LoggerSettings { id: logger }
    property HealthMetricsLoader _metrics: HealthMetricsLoader {
        id: metricsLoader
        onDataChanged: data.touch()
        // a key of the Health profile changed: every day's numbers may be others, not only today's and
        // yesterday's (dataChanged follows)
        onProfileChanged: data._store.days = {}
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
    property WorkoutLoader _workoutLoader: WorkoutLoader {
        id: workoutLoader
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
        _store.resting = {}
        _store.sleep = null
        _store.workouts = {}
        _store.skin = {}
        _store.skinWeek = {}
        _store.zoneWeek = {}
        _store.inactive = {}
        _store.cardio = {}
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

    // the main goal, { type: steps, calories, distance, floors or azm; target } (R5 E-18: the phone's; steps, the
    // step goal, when it has set none)
    function mainGoal() {
        var g = metricsLoader.mainGoal()
        if (!g || Format.goalType(g.type) === "steps")
            return { type: "steps", target: stepGoal }
        return { type: Format.goalType(g.type), target: Math.max(1, Number(g.target) || 1) }
    }

    // a day's longest inactive span (R5 E-21, stock's "Most inactive today"): { startMs, endMs, minutes } (minutes 0:
    // none), cached until the files change
    function inactiveOf(date) {
        var key = Stats.dayKey(date)
        if (_store.inactive[key] === undefined) {
            var h = metricsLoader.hourly(Stats.addDays(date, 0))
            _store.inactive[key] = { startMs: Number(h.inactiveStartMs) || 0, endMs: Number(h.inactiveEndMs) || 0,
                                     minutes: Number(h.inactiveMin) || 0 }
        }
        return _store.inactive[key]
    }

    // a day's cardio load and its target (R5 E-09: sensorlogd's HealthMetricsLoader.cardioLoad), cached until the
    // files change
    function cardioLoad(date) {
        var key = Stats.dayKey(date)
        if (_store.cardio[key] === undefined)
            _store.cardio[key] = metricsLoader.cardioLoad(Stats.addDays(date, 0))
        return _store.cardio[key]
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

    // The resting heart rate of a day, -1 if it has none: the one sensorlogd estimated once for the
    // day (stock: "estimated once a day"; sensorlogd metrics/restingHr.h: the median of the still,
    // worn minutes of 24 hours, in the morning with the night or at the day's close), cached
    function restingOf(date) {
        var key = Stats.dayKey(date)
        if (_store.resting[key] === undefined)
            _store.resting[key] = metricsLoader.restingHrOf(Stats.addDays(date, 0))
        return _store.resting[key]
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

    // the Active Zone Minutes of the week (Monday to `date`), as HealthMetricsLoader.azmWeek: the days'
    // zone minutes from one read of the week (HealthMetricsLoader.zoneDays, the numbers of the day
    // summaries without their steps and barometer files), cached until the files change
    function azmWeek(date) {
        var key = Stats.dayKey(date)
        if (_store.zoneWeek[key] === undefined) {
            var dow = (date.getDay() + 6) % 7
            _store.zoneWeek[key] = metricsLoader.zoneDays(Stats.addDays(date, -dow), Stats.addDays(date, 0))
        }
        var days = _store.zoneWeek[key]
        var total = 0
        for (var i = 0; i < days.length; i++)
            total += days[i].azm || 0
        return total
    }

    // The workouts of the week of `date` (Monday to the date, as the Active Zone Minutes week), newest first:
    // WorkoutLoader.workouts (startMs, endMs, activeS, type, distanceM, kcal, azm, moderateS, vigorousS, peakS,
    // ended), cached until health.db changes
    function weekWorkouts(date) {
        var key = Stats.dayKey(date)
        if (_store.workouts[key] === undefined) {
            var dow = (date.getDay() + 6) % 7
            _store.workouts[key] = workoutLoader.workouts(Stats.addDays(date, -dow), Stats.addDays(date, 0))
        }
        return _store.workouts[key]
    }

    // M4 WO-13: the skin temperature variation of a morning as stock's card shows it (HealthMetricsLoader.skinTemp:
    // state noData, calibrating, tracking, analyzing, inRange, aboveRange, belowRange; nightsLeft; hasVariation, devC,
    // loC, hiC in deg C), and the seven mornings up to it ({ date, hasVariation, devC, loC, hiC, state }), cached
    function skinTemp(date) {
        var key = Stats.dayKey(date)
        if (_store.skin[key] === undefined)
            _store.skin[key] = metricsLoader.skinTemp(Stats.addDays(date, 0))
        return _store.skin[key]
    }
    function skinTempWeek(date) {
        var key = Stats.dayKey(date)
        if (_store.skinWeek[key] === undefined)
            _store.skinWeek[key] = metricsLoader.skinTempWeek(Stats.addDays(date, 0))
        return _store.skinWeek[key]
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
