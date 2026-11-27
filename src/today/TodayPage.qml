/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

import "../data"
import "../data/HealthStats.js" as Stats
import "../data/HealthFormat.js" as Format
import "../theme"
import "../ui"

/*
 * The Health app's first screen as stock's Today list (TodayRoute, health-fitness-02): a scrolling
 * list (a ScalingList: the TransformingLazyColumn's edge scaling) with the main goal ring (its type the phone's: steps,
 * energy, distance, floors or Active Zone Minutes, R5 E-18; a tap opens that metric's page), then one
 * card per metric in stock's order: Steps, Energy burned, Distance, Floors, Active Zone Minutes,
 * Exercise days (stock's stat 6, EXERCISE: uxo.java; M4 WO-10), Hourly activity, Heart rate, Resting
 * heart rate, Sleep, Skin temp variation (stock's stat 14, SKIN_TEMP, HEALTH: uxx.java; M4 WO-13), Cardio load (R5
 * E-09: the day's load and its target, CardioLoadCardViewModel). No title (the
 * curved time of the app sits at the top as in the other apps). A tap on a card says which one it is: opened(key).
 */
Item {
    id: page

    // set by the LayerStack
    property int depth
    property var pop

    signal opened(string key)

    // the rows: rebuilt whenever the data changed (HealthData.version)
    readonly property var rows: build(HealthData.version)
    readonly property alias list: list

    function card(key, title, icon, category, value, unit, subtitle, textValue, progress) {
        return { type: "card", key: key, title: title, icon: icon, category: category, value: value,
                 unit: unit, subtitle: subtitle, textValue: textValue === true,
                 progress: progress === undefined ? -1 : progress }
    }

    function build(version) {
        var t = HealthData.today
        var s = HealthData.summary(t)
        var steps = HealthData.stepsOf(t)
        var main = HealthData.mainGoal()
        var goalValue = Format.goalValue(main.type, s, steps)
        var hr = HealthData.heartDay(t)
        var resting = HealthData.restingOf(t)
        var night = HealthData.sleep()
        var skin = HealthData.skinTemp(t)
        var out = []

        //% "Steps"
        var tSteps = qsTrId("id-steps")
        //% "Energy burned"
        var tEnergy = qsTrId("id-energy-burned")
        //% "Cal"
        var uCal = qsTrId("id-unit-cal")
        //% "Distance"
        var tDistance = qsTrId("id-distance")
        //% "Floors"
        var tFloors = qsTrId("id-floors")
        //% "Active Zone Minutes"
        var tAzm = qsTrId("id-azm")
        //% "%1 of %2 this week"
        //: %1 is the Active Zone Minutes of this week so far, %2 the weekly goal (150)
        var sAzm = qsTrId("id-azm-week")
        //% "Exercise days"
        var tExercise = qsTrId("id-exercise-days")
        //% "%1 of %2 days this week"
        //: %1 is the days of this week with a workout, %2 the goal (3); stock plurals 0x7f12005c
        var sExercise = qsTrId("id-exercise-days-week")
        //% "Hourly activity"
        var tHourly = qsTrId("id-hourly-activity")
        //% "Heart rate"
        var tHeart = qsTrId("id-heart-rate")
        //% "bpm"
        var uBpm = qsTrId("id-bpm")
        //% "No recent heart rate"
        var sNoHr = qsTrId("id-no-recent-hr")
        //% "Resting heart rate"
        var tResting = qsTrId("id-resting-heart-rate")
        //% "Sleep"
        var tSleep = qsTrId("id-sleep")
        //% "No data yet"
        var sNoData = qsTrId("id-no-data-yet")
        //% "Skin temp variation"
        var tSkin = qsTrId("id-skin-temp-variation")
        //% "Last sleep session"
        var sLastSleep = qsTrId("id-last-sleep-session")

        out.push({ type: "goal", key: Format.goalCardKey(main.type), caption: HealthText.goalCaption(main.type),
                   value: HealthText.goalValueText(main.type, goalValue), icon: Format.goalIcon(main.type),
                   subtitle: HealthText.goalText(goalValue, main.target, main.type),
                   fraction: Format.goalFraction(goalValue, main.target) })
        out.push(card("steps", tSteps, "eos-health-steps", "fitness", HealthText.number(steps), "", ""))
        out.push(card("energy", tEnergy, "eos-health-energy", "fitness",
                      HealthText.number(Format.energyValue(s.energyKcal)), uCal, ""))
        var dist = Format.distance(s.distanceM, HealthText.imperial)
        out.push(card("distance", tDistance, "eos-health-distance", "fitness",
                      dist.value.toLocaleString(Qt.locale(), "f", 2), dist.unit, ""))
        out.push(card("floors", tFloors, "eos-health-floors", "fitness", HealthText.number(s.floors || 0), "", ""))
        out.push(card("azm", tAzm, "eos-health-azm", "fitness", HealthText.number(s.azm || 0), "",
                      sAzm.arg(HealthText.number(HealthData.azmWeek(t))).arg(HealthText.number(HealthData.metrics.azmWeeklyGoal))))
        var week = Format.exerciseWeek(HealthData.weekWorkouts(t), Format.weekStartMs(t.getTime()))
        out.push(card("exercise", tExercise, "eos-exercise", "fitness", String(week.done), "",
                      sExercise.arg(week.done).arg(Format.EXERCISE_DAYS_GOAL)))
        out.push(card("hourly", tHourly, "eos-health-hourly", "fitness", String(s.hoursMet || 0), "",
                      HealthText.hourlyText(s.hoursMet || 0, s.hoursTotal || 0)))

        // the latest reading, if it is not older than two hours (stock: 'No heart rate data has been
        // collected in the last 2 hrs.', 'No recent heart rate')
        var fresh = hr.count > 0 && Stats.minutesAgo(hr.latestTime, Date.now() / 1000) <= 120
        out.push(card("heartrate", tHeart, "eos-health-heart", "health",
                      fresh ? String(hr.latest) : HealthText.none, uBpm,
                      fresh ? HealthText.ageText(hr.latestTime, Date.now()) : sNoHr))
        out.push(card("resting", tResting, "eos-health-resting", "health",
                      resting > 0 ? String(resting) : HealthText.none, uBpm, ""))
        // stock's Sleep card (aarf.java g(), c()): with a night, the time asleep and its score, a ring of the time
        // asleep against the sleep goal round the icon; without one "No data yet" and "Goal: %1$s" (R5 E-22)
        var sleepGoal = HealthData.sleepGoalOf(night)
        out.push(card("sleep", tSleep, "eos-health-sleep", "wellness",
                      night.valid ? HealthText.durationText(night.main.asleepMin) : sNoData, "",
                      night.valid ? (night.scoreLabel || "") : HealthText.sleepGoalText(sleepGoal), true,
                      night.valid ? Format.goalFraction(night.main.asleepMin, sleepGoal) : -1))
        // stock's card (acbf.java o(), aanu.java): the morning's variation against the personal range as a word,
        // "Last sleep session" under it; the thermometer with an arrow up above the range, down below it
        out.push(card("skintemp", tSkin, Format.skinTempIcon(skin.state), "health", HealthText.skinTempStateText(skin),
                      "", Format.skinTempHasValue(skin.state) ? sLastSleep : "", true))
        // stock's Cardio load card: the day's load, the target under it (R5 E-09)
        var cardio = HealthData.cardioLoad(t)
        //% "Cardio load"
        var tCardio = qsTrId("id-cardio-load")
        out.push(card("cardioload", tCardio, "ms-monitor_heart", "fitness", HealthText.number(cardio.load || 0), "",
                      HealthText.cardioTargetText(cardio)))
        out.push({ type: "settings", key: "settings" })
        return out
    }

    ScalingList {
        id: list
        objectName: "todayList"
        anchors.fill: parent
        model: page.rows
        itemDelegate: Item {
            id: row
            property var modelData
            property int index
            height: inner.height

            // the row is as wide as the list's and as tall as its card: the card's own height
            Loader {
                id: inner
                width: row.width
                sourceComponent: !row.modelData ? null : row.modelData.type === "goal" ? goalComponent :
                                 row.modelData.type === "settings" ? settingsComponent : cardComponent
            }
            Component {
                id: settingsComponent
                Button {
                    objectName: "settingsRow"
                    variant: "tonal"
                    iconName: "ios-settings-outline"
                    //% "Settings"
                    text: qsTrId("id-settings")
                    onClicked: page.opened("settings")
                }
            }
            Component {
                id: goalComponent
                GoalCard {
                    objectName: "goalCard"
                    value: row.modelData.value
                    caption: row.modelData.caption
                    subtitle: row.modelData.subtitle
                    fraction: row.modelData.fraction
                    iconName: row.modelData.icon
                    onClicked: page.opened(row.modelData.key)
                }
            }
            Component {
                id: cardComponent
                MetricCard {
                    objectName: "card-" + row.modelData.key
                    title: row.modelData.title
                    iconName: row.modelData.icon
                    category: row.modelData.category
                    value: row.modelData.value
                    unit: row.modelData.unit
                    subtitle: row.modelData.subtitle
                    textValue: row.modelData.textValue
                    progress: row.modelData.progress
                    onClicked: page.opened(row.modelData.key)
                }
            }
        }
    }
}
