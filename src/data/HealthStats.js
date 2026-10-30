/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Day summaries of the sensorlogd day files, for the history pages.
 *
 * The loaders (HrDataLoader, StepsDataLoader) give one day file as a list
 * of points: x is the UNIX time of the record, y its value (bpm, or the
 * steps walked so far that day). Everything here works on one day at a
 * time, so a page only ever reads the days it shows.
 *
 * Days are local calendar days: a day starts at local midnight and ends at
 * the next one (23 or 25 hours on a daylight saving change).
 */

.pragma library

/* A logged heart rate outside these is no reading: 0 is "off the wrist",
 * the rest is beyond what a wrist sensor reports */
var HR_MIN_VALID = 25
var HR_MAX_VALID = 250

/* Resting heart rate: the lowest average heart rate held for this long,
 * over at least this many readings (sensorlogd logs about one reading
 * every 10 minutes at rest, so 30 minutes holds 3) */
var RESTING_WINDOW = 1800
var RESTING_MIN_READINGS = 3

/* Stock Fitbit/Wear OS daily step goal, used when none is set */
var DEFAULT_STEP_GOAL = 10000

function dayStart(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime() / 1000
}

function dayEnd(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1).getTime() / 1000
}

/* The day n days after date, at noon (away from any daylight saving hour) */
function addDays(date, n) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + n, 12)
}

/* Calendar days from a to b (b later: positive) */
function daysBetween(a, b) {
    var da = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate())
    var db = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate())
    return Math.round((db - da) / 86400000)
}

function sameDay(a, b) {
    return daysBetween(a, b) === 0
}

function dayKey(date) {
    var m = date.getMonth() + 1
    var d = date.getDate()
    return date.getFullYear() + "-" + (m < 10 ? "0" : "") + m + "-" + (d < 10 ? "0" : "") + d
}

/* 0 today, 1 yesterday, 2 to 6 this past week (named by weekday), 7 older,
 * -1 in the future */
function dayKind(date, today) {
    var n = daysBetween(date, today)
    if (n < 0)
        return -1
    return n > 6 ? 7 : n
}

/* Where the local clock time hour:00 of the day is, from 0 (midnight) to
 * 1 (the next midnight) */
function hourFraction(date, hour) {
    var s = dayStart(date)
    var e = dayEnd(date)
    var t = new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour).getTime() / 1000
    return (t - s) / (e - s)
}

/* The records of a loader as [{t, v}] in time order, without the ones that
 * are no number */
function _points(data) {
    var out = []
    if (!data)
        return out
    for (var i = 0; i < data.length; i++) {
        var p = data[i]
        if (p === null || p === undefined)
            continue
        var t = Number(p.x)
        var v = Number(p.y)
        if (isFinite(t) && isFinite(v))
            out.push({ t: t, v: v })
    }
    out.sort(function(a, b) { return a.t - b.t })
    return out
}

/* The valid heart rate readings of the day [start, end) */
function heartRates(data, start, end) {
    return _points(data).filter(function(p) {
        return p.t >= start && p.t < end && p.v >= HR_MIN_VALID && p.v <= HR_MAX_VALID
    })
}

/* The resting heart rate of time ordered readings, -1 if no stretch of
 * RESTING_WINDOW holds RESTING_MIN_READINGS of them */
function restingRate(points) {
    var best = Infinity
    var j = 0
    var sum = 0
    for (var i = 0; i < points.length; i++) {
        if (j < i) {
            j = i
            sum = 0
        }
        while (j < points.length && points[j].t < points[i].t + RESTING_WINDOW) {
            sum += points[j].v
            j++
        }
        var count = j - i
        if (count >= RESTING_MIN_READINGS)
            best = Math.min(best, sum / count)
        sum -= points[i].v
    }
    return isFinite(best) ? Math.round(best) : -1
}

/* The heart rate of one day: count, min, max, resting (-1: not enough
 * readings), latestTime, latest (0 if no reading), buckets: the low and
 * high of each of the n equal parts of the day ({lo, hi}, null if none),
 * and latestBucket: the part of the latest reading (-1 if none) */
function heartRateDay(data, date, n) {
    var start = dayStart(date)
    var end = dayEnd(date)
    var pts = heartRates(data, start, end)
    var r = { count: pts.length, min: 0, max: 0, resting: -1, latestTime: 0, latest: 0, buckets: [], latestBucket: -1 }
    n = n || 48
    for (var b = 0; b < n; b++)
        r.buckets.push(null)
    if (pts.length === 0)
        return r
    r.min = pts[0].v
    r.max = pts[0].v
    for (var i = 0; i < pts.length; i++) {
        var v = pts[i].v
        r.min = Math.min(r.min, v)
        r.max = Math.max(r.max, v)
        var k = Math.min(n - 1, Math.floor((pts[i].t - start) / (end - start) * n))
        var bucket = r.buckets[k]
        if (bucket)
            r.buckets[k] = { lo: Math.min(bucket.lo, v), hi: Math.max(bucket.hi, v) }
        else
            r.buckets[k] = { lo: v, hi: v }
    }
    var last = pts[pts.length - 1]
    r.latestTime = last.t
    r.latestBucket = Math.min(n - 1, Math.floor((last.t - start) / (end - start) * n))
    r.latest = Math.round(last.v)
    r.min = Math.round(r.min)
    r.max = Math.round(r.max)
    r.resting = restingRate(pts)
    return r
}

/* The steps of one day: total (the most counted that day) and hours: the
 * steps walked in each local clock hour (24; a record past the day, such
 * as a day's last total written after midnight, counts in the last hour).
 * Each record is the day's count so far; a count lower than one before it
 * (a counter restart) adds nothing. */
function stepsDay(data, date) {
    var start = dayStart(date)
    var end = dayEnd(date)
    var pts = _points(data)
    var r = { count: 0, total: 0, hours: [] }
    for (var h = 0; h < 24; h++)
        r.hours.push(0)
    var counted = 0
    for (var i = 0; i < pts.length; i++) {
        var v = pts[i].v
        if (v < 0)
            continue
        r.count++
        var hour = pts[i].t < start ? 0 : pts[i].t >= end ? 23 : new Date(pts[i].t * 1000).getHours()
        if (v > counted) {
            r.hours[hour] += v - counted
            counted = v
        }
    }
    r.total = Math.round(counted)
    return r
}

/* Axis labels for values lo..hi: intervals equal steps, each a multiple of
 * unit: {lo, hi, ticks} */
function axis(lo, hi, intervals, unit) {
    if (!(hi > lo))
        hi = lo + unit
    var a = Math.floor(lo / unit) * unit
    var step = Math.max(unit, Math.ceil((hi - lo) / intervals / unit) * unit)
    while (a + step * intervals < hi)
        step += unit
    var ticks = []
    for (var i = 0; i <= intervals; i++)
        ticks.push(a + step * i)
    return { lo: a, hi: a + step * intervals, ticks: ticks }
}

/* The heart rate axis of the readings lo..hi: 3 labels, 10s of bpm, and at
 * least 40 bpm tall so that a calm day is not drawn as wild swings */
function heartRateAxis(lo, hi) {
    if (hi - lo < 40) {
        var mid = (lo + hi) / 2
        lo = Math.max(0, mid - 20)
        hi = lo + 40
    }
    return axis(lo, hi, 2, 10)
}

/* The step count axis of 0..max: 3 labels */
function stepsAxis(max) {
    var unit = max >= 1000 ? Math.pow(10, Math.floor(Math.log(max) / Math.LN10) - 1) : 100
    return axis(0, Math.max(max, 1), 2, Math.max(1, unit))
}

/* A count of steps or bpm for an axis label: 1200 -> 1.2k */
function shortNumber(v) {
    if (v >= 1000)
        return (Math.round(v / 100) / 10) + "k"
    return String(Math.round(v))
}

/* Whole minutes from t to now (seconds), -1 if t is later than now */
function minutesAgo(t, now) {
    var d = now - t
    return d < 0 ? -1 : Math.floor(d / 60)
}
