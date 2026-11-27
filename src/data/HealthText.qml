/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma Singleton

import QtQuick
import org.asteroid.controls

import "HealthStats.js" as Stats
import "HealthFormat.js" as Format

/*
 * The words of the Health screens that depend on a number: stock's wording (the strings of the
 * Fitbit app of CP3A, cited per text), in the user's language, and times in the user's 12 or
 * 24 hour format (TimeFormat, health-fitness-13).
 */
QtObject {
    readonly property var locale: Qt.locale()
    // a missing value: 0x7f14036a
    readonly property string none: "- -"
    // the phone app that holds the rest of the data (stock: 'open the Google Health mobile app'); ours
    // is the one that syncs the watch
    readonly property string phoneApp: "Gadgetbridge"

    function number(n) {
        return Math.round(n).toLocaleString(locale, "f", 0)
    }

    // the main goal's subtitle (health-fitness-02): '%1$s left' / 'Goal met' / '%1$s over goal'
    // (plurals 0x7f120121, 0x7f1404d0 'Goal met!' is the celebration; 0x7f140dbf, 0x7f140dd7); the amount in the
    // main goal's unit (R5 E-18: type, steps by default; a distance in metres is written in the locale's unit)
    function goalText(steps, goal, type) {
        var distance = Format.goalType(type) === "distance"
        // a distance compared in tens of metres (the text has two decimals of a kilometre or mile)
        var g = distance ? Format.goalState(steps / 10, goal / 10) : Format.goalState(steps, goal)
        var amount = distance ? distanceText(g.amount * 10) : number(g.amount)
        if (g.state === "left")
            //% "%1 left"
            //: %1 is a number of steps
            return qsTrId("id-goal-left").arg(amount)
        if (g.state === "met")
            //% "Goal met"
            return qsTrId("id-goal-met")
        //% "%1 over goal"
        //: %1 is a number of steps
        return qsTrId("id-goal-over").arg(amount)
    }

    // the main goal's value in its ring (R5 E-18): steps, Cal, floors and minutes as whole numbers, a distance with
    // two decimals and its unit
    function goalValueText(type, value) {
        if (Format.goalType(type) === "distance")
            return distanceText(value)
        return number(value)
    }
    // the main goal's name under its value: the Today card's title of its metric
    function goalCaption(type) {
        switch (Format.goalType(type)) {
        case "calories": return qsTrId("id-energy-burned")
        case "distance": return qsTrId("id-distance")
        case "floors": return qsTrId("id-floors")
        case "azm": return qsTrId("id-azm")
        }
        return qsTrId("id-steps")
    }

    // Hourly activity's subtitle: '%1$d of %2$d hr' / 'Completed today' (0x7f140c82)
    function hourlyText(met, total) {
        var h = Format.hourlyState(met, total)
        if (h.state === "done")
            //% "Completed today"
            return qsTrId("id-hourly-done")
        //% "%1 of %2 hr"
        //: %1 is the hours of this day with 250 steps, %2 the hours that count (9)
        return qsTrId("id-hourly-progress").arg(h.met).arg(h.total)
    }

    // when the latest heart rate was taken: 'Just now', '5 min ago', else the time of day
    function ageText(timeSec, nowMs) {
        var m = Stats.minutesAgo(timeSec, nowMs / 1000)
        if (m < 1)
            //% "Just now"
            return qsTrId("id-hr-just-now")
        if (m < 60)
            //% "%1 min ago"
            //: %1 is a number of minutes
            return qsTrId("id-hr-min-ago").arg(m)
        return TimeFormat.time(new Date(timeSec * 1000))
    }

    // the distance with its unit, in the locale's units
    function distanceText(metres) {
        return Format.distanceText(metres, imperial, locale)
    }
    readonly property bool imperial: locale.measurementSystem !== Locale.MetricSystem

    // "7 hr 12 min", "7 hr", "45 min"
    function durationText(minutes) {
        var hm = Format.hoursMinutes(minutes)
        if (hm.hours === 0)
            //% "%1 min"
            //: %1 is a number of minutes
            return qsTrId("id-duration-min").arg(hm.minutes)
        if (hm.minutes === 0)
            //% "%1 hr"
            //: %1 is a number of hours
            return qsTrId("id-duration-hr").arg(hm.hours)
        //% "%1 hr %2 min"
        //: %1 is a number of hours, %2 of minutes
        return qsTrId("id-duration-hr-min").arg(hm.hours).arg(hm.minutes)
    }

    // 'Today', 'Yesterday', the weekday of this week, else "Mon 3 Nov"
    function dayText(d, today) {
        switch (Stats.dayKind(d, today)) {
        case 0:
            //% "Today"
            return qsTrId("id-today")
        case 1:
            //% "Yesterday"
            return qsTrId("id-yesterday")
        case 2: case 3: case 4: case 5: case 6:
            return d.toLocaleDateString(locale, "dddd")
        default:
            return d.toLocaleDateString(locale, "ddd d MMM")
        }
    }

    // M4 WO-13: the Skin temp variation card's word for its state (stock aanu.java e(): 'In range' 0x7f1409bc,
    // 'Above range' 0x7f140022, 'Below range' 0x7f140095, plurals 0x7f12013b 'Wear to sleep one more time' /
    // '... %1$d more times', 'Tracking…' 0x7f140cee, 'Analyzing…' 0x7f140ce3, 'Wear your watch to sleep' 0x7f140b87)
    function skinTempStateText(view) {
        switch (view ? view.state : "") {
        case "inRange":
            //% "In range"
            return qsTrId("id-in-range")
        case "aboveRange":
            //% "Above range"
            return qsTrId("id-above-range")
        case "belowRange":
            //% "Below range"
            return qsTrId("id-below-range")
        case "calibrating":
            if (view.nightsLeft === 1)
                //% "Wear to sleep one more time"
                return qsTrId("id-wear-to-sleep-one-more")
            //% "Wear to sleep %1 more times"
            //: %1 is a number of nights (2 or more)
            return qsTrId("id-wear-to-sleep-more").arg(view.nightsLeft)
        case "tracking":
            //% "Tracking…"
            return qsTrId("id-tracking")
        case "analyzing":
            //% "Analyzing…"
            return qsTrId("id-analyzing")
        default:
            //% "Wear your watch to sleep"
            return qsTrId("id-wear-to-sleep")
        }
    }

    // the line under the state on its page (stock aage.java: 0x7f140eaa while the baseline is made, 0x7f140023
    // above the range, 0x7f140096 below it)
    function skinTempExplanation(state) {
        if (state === "calibrating")
            //% "Skin temperature variation is the fluctuation in temperature taken from your wrist while you sleep"
            return qsTrId("id-skin-temp-explained")
        if (state === "aboveRange")
            //% "May be associated with warmer surroundings or other factors"
            return qsTrId("id-skin-temp-warmer")
        if (state === "belowRange")
            //% "May be associated with cooler surroundings or other factors"
            return qsTrId("id-skin-temp-cooler")
        return ""
    }

    // a variation with its unit, one decimal: "0.4°C", "-0.3°C" (stock 0x7f140953 '%1$.1f%2$s', 0x7f1408fc/fd)
    function skinTempValueText(c, fahrenheit) {
        return Format.skinTempDelta(c, fahrenheit).toLocaleString(locale, "f", 1) + (fahrenheit ? "°F" : "°C")
    }

    // a week: 'Last 7 days' when it ends today
    function weekText(end, today) {
        if (Stats.daysBetween(end, today) === 0)
            //% "Last 7 days"
            return qsTrId("id-last-7-days")
        return Stats.addDays(end, -6).toLocaleDateString(locale, "d MMM") + " - " + end.toLocaleDateString(locale, "d MMM")
    }
}
