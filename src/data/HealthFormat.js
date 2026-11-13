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
function goalState(steps, goal) {
    steps = Math.max(0, Math.round(steps))
    goal = Math.max(1, Math.round(goal))
    if (steps < goal)
        return { state: "left", amount: goal - steps }
    if (steps === goal)
        return { state: "met", amount: 0 }
    return { state: "over", amount: steps - goal }
}

/* The ring of the main goal: 0..1, a goal passed fills it */
function goalFraction(steps, goal) {
    return Math.max(0, Math.min(1, steps / Math.max(1, goal)))
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

/* Kelvin as the weather app shows temperatures: whole degrees Celsius (or Fahrenheit) */
function temperature(kelvin, fahrenheit) {
    var c = kelvin - 273
    return fahrenheit ? Math.round(c * 9 / 5 + 32) : Math.round(c)
}
