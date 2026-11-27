/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*
 * What the Health cards and detail pages say about their numbers (health-fitness-02, -08, -09).
 * Plain functions of numbers, so tests can run them without a screen: the texts themselves
 * (translated) are made by the pages from the states returned here.
 */

.pragma library
.import "HealthStats.js" as Stats

/* The steps against the goal, as the main goal card says it: "left" (goal - steps), "met" (the
 * goal exactly) and "over" (steps - goal). Stock '%1$s left' / 'Goal met' / '%1$s over goal'. */
// ---- Exercise days (M4 WO-10) ----
// the goal without the account's: stock 'new tuk(0, 3)' (ttd.java:168)
var EXERCISE_DAYS_GOAL = 3

// local midnight of the Monday of a time's week (ms): the week of sensorlogd's Active Zone Minutes
function weekStartMs(ms) {
    var d = new Date(ms)
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() - (d.getDay() + 6) % 7).getTime()
}

// The week of workouts (WorkoutLoader rows of the week that starts at weekStart, ms): the days with one
// that ended (days[0] Monday), how many, and the totals of those workouts: active time (s), Active Zone
// Minutes, kcal and the time in the Moderate, Vigorous and Peak zones (s)
function exerciseWeek(list, weekStart) {
    var out = { done: 0, days: [false, false, false, false, false, false, false], count: 0, activeS: 0, azm: 0, kcal: 0,
                moderateS: 0, vigorousS: 0, peakS: 0 }
    var start = new Date(weekStart)
    for (var i = 0; list && i < list.length; i++) {
        var w = list[i]
        if (!w || w.ended === false || !(Number(w.startMs) > 0))
            continue
        var at = new Date(Number(w.startMs))
        var day = Math.round((new Date(at.getFullYear(), at.getMonth(), at.getDate()) -
                              new Date(start.getFullYear(), start.getMonth(), start.getDate())) / 86400000)
        if (day < 0 || day > 6)
            continue
        if (!out.days[day]) {
            out.days[day] = true
            out.done++
        }
        out.count++
        out.activeS += Number(w.activeS) || 0
        out.azm += Number(w.azm) || 0
        out.kcal += Number(w.kcal) || 0
        out.moderateS += Number(w.moderateS) || 0
        out.vigorousS += Number(w.vigorousS) || 0
        out.peakS += Number(w.peakS) || 0
    }
    return out
}

// the workouts of a list that ended and began on the day that starts at dayStart (ms), as listed (newest first)
function dayWorkouts(list, dayStart) {
    var s = new Date(dayStart)
    var end = new Date(s.getFullYear(), s.getMonth(), s.getDate() + 1).getTime()
    var out = []
    for (var i = 0; list && i < list.length; i++) {
        var w = list[i]
        if (w && w.ended !== false && Number(w.startMs) >= dayStart && Number(w.startMs) < end)
            out.push(w)
    }
    return out
}

function goalState(steps, goal) {
    steps = Math.max(0, Math.round(steps))
    goal = Math.max(1, Math.round(goal))
    if (steps < goal)
        return { state: "left", amount: goal - steps }
    if (steps === goal)
        return { state: "met", amount: 0 }
    return { state: "over", amount: steps - goal }
}

/* Morning Brief (R5 E-10). Stock's brief is pages in MorningBriefPagesOrder (MorningBriefPagesOrder.java: LANDING 0,
 * SLEEP 1, READINESS 2, HEALTH METRICS 3-4, EXERCISE 5, ACTIVITY PLANS 6, WEATHER 7, OUTRO 8); the ones this watch has
 * data for, in that order. The Today list's Morning Brief card (MorningBriefCardViewModel: "Morning Brief"
 * 0x7f140aff) shows in the morning: from 04:00 to 12:00, the launcher's morning (modescore.h MorningFromHour /
 * MorningToHour; guess: stock's card follows its brief). The outro's line is one of stock's five (0x7f140b00-04),
 * one a day. */
var MORNING_PAGES = ["landing", "sleep", "exercise", "weather", "outro"]
var MORNING_FROM_HOUR = 4
var MORNING_TO_HOUR = 12
function morningCardShown(date) {
    var h = date.getHours()
    return h >= MORNING_FROM_HOUR && h < MORNING_TO_HOUR
}
// which of the outro's five lines a day has (0..4): by the day of the year, so a day keeps its line
function outroLine(date) {
    var start = new Date(date.getFullYear(), 0, 1)
    var day = Math.round((new Date(date.getFullYear(), date.getMonth(), date.getDate()) - start) / 86400000)
    return day % 5
}

/* The ring of the main goal: 0..1, a goal passed fills it */
function goalFraction(steps, goal) {
    return Math.max(0, Math.min(1, steps / Math.max(1, goal)))
}

/* The main goal (R5 E-18): stock's account has one primary goal of the types STEPS, CALORIES, DISTANCE, FLOORS and AZM
 * (PrimaryGoalType), set on the phone; sensorlogd's HealthMetricsLoader.mainGoal() reads it ({ type, target }). The
 * day's value of its metric (calories: the energy burned, kcal; distance: metres) from a day summary and the day's
 * steps, the Today card it stands for and its icon (the cards'). */
var GOAL_TYPES = ["steps", "calories", "distance", "floors", "azm"]
function goalType(type) {
    return GOAL_TYPES.indexOf(String(type)) >= 0 ? String(type) : "steps"
}
function goalValue(type, summary, steps) {
    var s = summary || {}
    switch (goalType(type)) {
    case "calories": return Math.max(0, s.energyKcal || 0)
    case "distance": return Math.max(0, s.distanceM || 0)
    case "floors": return Math.max(0, s.floors || 0)
    case "azm": return Math.max(0, s.azm || 0)
    }
    return Math.max(0, steps || 0)
}
function goalCardKey(type) {
    return { steps: "steps", calories: "energy", distance: "distance", floors: "floors", azm: "azm" }[goalType(type)]
}
function goalIcon(type) {
    return { steps: "eos-health-steps", calories: "eos-health-energy", distance: "eos-health-distance",
             floors: "eos-health-floors", azm: "eos-health-azm" }[goalType(type)]
}

/* Hourly activity: "progress" (hoursMet of hoursTotal) or "done" ('Completed today') once every
 * hour of the day's window has its 250 steps. */
function hourlyState(hoursMet, hoursTotal) {
    if (hoursTotal > 0 && hoursMet >= hoursTotal)
        return { state: "done", met: hoursMet, total: hoursTotal }
    return { state: "progress", met: hoursMet, total: hoursTotal }
}

/* A distance in metres as { value, unit, miles }: kilometres with two decimals, or miles with two
 * (imperial: the locale's measurement system is not metric) */
function distance(metres, imperial) {
    var m = Math.max(0, metres || 0)
    if (imperial)
        return { value: m / 1609.344, unit: "mi", imperial: true }
    return { value: m / 1000, unit: "km", imperial: false }
}

/* A distance as text with the locale's decimal point: "3.52 km" */
function distanceText(metres, imperial, locale) {
    var d = distance(metres, imperial)
    return d.value.toLocaleString(locale, "f", 2) + " " + d.unit
}

/* Energy burned: whole kilocalories, the unit stock prints on its card ("Cal") */
function energyValue(kcal) {
    return Math.round(Math.max(0, kcal || 0))
}

/* The best day and the best hour of a list of days [{date, summary}] (summary: HealthMetricsLoader's
 * steps, distanceM, hourSteps[24]). Best day: the day with the most steps ({date, steps, distanceM},
 * null if no day has steps). Best hour: the hour of a day with the most steps ({date, hour, steps,
 * distanceM} - the distance by the day's stride: distance / steps -, null if none walked). Ties keep
 * the later day (the more recent one), as a list ordered by time. */
function best(days) {
    var day = null
    var hour = null
    for (var i = 0; i < days.length; i++) {
        var s = days[i].summary || {}
        var steps = s.steps || 0
        if (steps > 0 && (day === null || steps >= day.steps))
            day = { date: days[i].date, steps: steps, distanceM: s.distanceM || 0 }
        var hs = s.hourSteps || []
        for (var h = 0; h < hs.length; h++)
            if (hs[h] > 0 && (hour === null || hs[h] >= hour.steps))
                hour = { date: days[i].date, hour: h, steps: hs[h],
                         distanceM: steps > 0 ? (s.distanceM || 0) * hs[h] / steps : 0 }
    }
    return { day: day, hour: hour }
}

/* The average of the steps of the days of a week that have any (-1 if none) */
function averageSteps(days) {
    var sum = 0
    var n = 0
    for (var i = 0; i < days.length; i++) {
        var s = (days[i].summary || {}).steps || 0
        if (s > 0) {
            sum += s
            n++
        }
    }
    return n ? Math.round(sum / n) : -1
}

/* A heart rate range for 'Heart rate range': "58 - 112" or "- -" for no readings. The texts around it
 * ('%1$s - %2$s bpm') belong to the page; this gives the two numbers (strings) */
function range(min, max, count) {
    if (!(count > 0))
        return { has: false, low: "- -", high: "- -" }
    return { has: true, low: String(min), high: String(max) }
}

/* Minutes of a day spent in each zone as {light, moderate, vigorous, peak, total} from a summary */
function zoneMinutes(s) {
    var light = (s && s.zoneLight) || 0
    var moderate = (s && s.zoneModerate) || 0
    var vigorous = (s && s.zoneVigorous) || 0
    var peak = (s && s.zonePeak) || 0
    return { light: light, moderate: moderate, vigorous: vigorous, peak: peak, total: light + moderate + vigorous + peak }
}

/* The readings of a day as one value per minute: [{t (the minute's start, s), v (the mean bpm)}] */
function minuteMeans(points) {
    var out = []
    var cur = null
    var sum = 0
    var n = 0
    for (var i = 0; i < points.length; i++) {
        var minute = Math.floor(points[i].t / 60)
        if (cur !== minute) {
            if (cur !== null)
                out.push({ t: cur * 60, v: sum / n })
            cur = minute
            sum = 0
            n = 0
        }
        sum += points[i].v
        n++
    }
    if (cur !== null)
        out.push({ t: cur * 60, v: sum / n })
    return out
}

/* The mean of the resting heart rate of the days that have one (-1 if none): days is a list of the
 * HealthStats.heartRateDay summaries */
function restingAverage(days) {
    var sum = 0
    var n = 0
    for (var i = 0; i < days.length; i++)
        if (days[i].resting > 0) {
            sum += days[i].resting
            n++
        }
    return n ? Math.round(sum / n) : -1
}

/* Sleep as "7 hr 12 min": the hours and minutes of a number of minutes ({hours, minutes}) */
function hoursMinutes(min) {
    min = Math.max(0, Math.round(min || 0))
    return { hours: Math.floor(min / 60), minutes: min % 60 }
}

/* The weather condition group of an OpenWeather id as an icon name of the Weather app */
function weatherIcon(id) {
    id = Number(id)
    if (id >= 200 && id < 300) return "ios-thunderstorm-outline"
    if (id >= 300 && id < 400) return "ios-drizzle-outline"
    if (id === 511) return "ios-snow-outline"
    if (id >= 500 && id < 600) return "ios-rainy-outline"
    if (id >= 600 && id < 700) return "ios-snow-outline"
    if (id >= 700 && id < 800) return "ios-cloudy-outline"
    if (id === 800) return "ios-sunny-outline"
    if (id === 801) return "ios-partly-sunny-outline"
    if (id > 801 && id < 900) return "ios-cloudy-outline"
    return "ios-alert-outline"
}

/* M4 WO-13, the skin temperature variation (asteroid-sensorlogd metrics/skinTemp.h). A variation in deg C as the
   user's unit shows it, to one decimal (stock yqk.java k(): x 10, rounded); deg F: a difference, x 1.8 */
function skinTempDelta(c, fahrenheit) {
    var v = fahrenheit ? c * 9 / 5 : c
    return Math.round(v * 10) / 10
}

/* the states that show a night's value, with "Last sleep session" under it (stock: aadz, aaed, aadx) */
function skinTempHasValue(state) {
    return state === "inRange" || state === "aboveRange" || state === "belowRange"
}

/* the card's icon: a thermometer, with an arrow up above the range and down below it (stock's
   gs_thermometer_gain / _loss) */
function skinTempIcon(state) {
    if (state === "aboveRange")
        return "eos-health-skintemp-up"
    if (state === "belowRange")
        return "eos-health-skintemp-down"
    return "eos-health-skintemp"
}

/* the week's nights with a value, and those in the range: { inRange, total } ("In range this week") */
function skinTempInRange(week) {
    var total = 0
    var inside = 0
    for (var i = 0; i < week.length; i++) {
        if (!week[i].hasVariation)
            continue
        total++
        if (week[i].state === "inRange")
            inside++
    }
    return { inRange: inside, total: total }
}

/* the week chart's axis: whole degrees either side of 0, at least 1, wide enough for the week's ranges and values */
function skinTempTicks(week, fahrenheit) {
    var m = 1
    for (var i = 0; i < week.length; i++) {
        var n = week[i]
        if (!n.hasVariation)
            continue
        var far = Math.max(Math.abs(skinTempDelta(n.devC, fahrenheit)), Math.abs(skinTempDelta(n.loC, fahrenheit)),
                           Math.abs(skinTempDelta(n.hiC, fahrenheit)))
        m = Math.max(m, Math.ceil(far))
    }
    return [-m, 0, m]
}

/* Kelvin as the weather app shows temperatures: whole degrees Celsius (or Fahrenheit) */
function temperature(kelvin, fahrenheit) {
    var c = kelvin - 273
    return fahrenheit ? Math.round(c * 9 / 5 + 32) : Math.round(c)
}
