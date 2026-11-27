/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import org.asteroid.controls

import "../data"
import "../data/HealthFormat.js" as Format
import "../data/ExerciseNames.js" as Names
import "../theme"
import "../ui"

// The Exercise card's page of stock (TodayRoute.Details("EXERCISE"): ExerciseDetailsViewModel.java, xny.java:40-110,
// wna.java cases 12-13): the days of this week with a workout against the goal, with the week's days, then 'Today'
// and today's workouts, then 'This week' and the totals of the week's workouts: Total exercise time, Active Zone
// Minutes, Calories, the Moderate, Vigorous and Peak minutes (zone time). The workouts are asteroid-sensorlogd's
// (health.db, HealthData.weekWorkouts). The goal is stock's when the account has none (3 days, ttd.java:168); the
// week starts on Monday as sensorlogd's Active Zone Minutes week (stock: the account's first day). Stock's last
// row, the 'Exercise' button that opens the Exercise app, is not here: an app cannot start another one on this
// watch (the launcher's tiles and complications do). FITNESS colours.
HealthPage {
    id: page
    readonly property var tones: HealthPalette.fitness
    readonly property date today: HealthData.today
    readonly property var workouts: {
        HealthData.version
        return HealthData.weekWorkouts(HealthData.today)
    }
    readonly property real weekStart: Format.weekStartMs(today.getTime())
    readonly property var week: Format.exerciseWeek(workouts, weekStart)
    readonly property var todays: Format.dayWorkouts(workouts, new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime())

    //% "Exercise days"
    title: qsTrId("id-exercise-days")
    //% "Exercise"
    readonly property string exerciseWord: qsTrId("id-exercise")

    // the first letter of the name of the week's day i (0: Monday)
    function dayLetter(i) {
        var d = new Date(weekStart)
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() + i).toLocaleDateString(Qt.locale(), "ddd").charAt(0)
    }

    StatBlock {
        objectName: "exerciseDaysWeek"
        //% "Days this week"
        caption: qsTrId("id-days-this-week")
        //% "%1 of %2"
        //: %1 is the days of this week with a workout, %2 the goal (3)
        value: qsTrId("id-days-of").arg(page.week.done).arg(Format.EXERCISE_DAYS_GOAL)
        valueRole: "numeralSmall"
        valueColor: page.tones.main
    }

    // the week's days, Monday first: filled where a workout began
    Row {
        id: days
        objectName: "exerciseWeekDays"
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.dp(3)
        Repeater {
            model: 7
            delegate: Rectangle {
                id: dot
                required property int index
                readonly property bool done: page.week.days[dot.index] === true
                objectName: "exerciseDay" + dot.index
                width: Theme.dp(20)
                height: width
                radius: width / 2
                color: done ? page.tones.main : HealthPalette.track
                Label {
                    anchors.centerIn: parent
                    text: page.dayLetter(dot.index)
                    role: "labelSmall"
                    color: dot.done ? page.tones.deep : HealthPalette.label
                }
            }
        }
    }

    SectionLabel {
        //% "Today"
        text: qsTrId("id-today")
    }
    Repeater {
        model: page.todays
        delegate: StatBlock {
            required property var modelData
            required property int index
            objectName: "exerciseToday" + index
            caption: Names.name(modelData.type) + " · " + TimeFormat.time(new Date(Number(modelData.startMs)))
            value: HealthText.durationText(Math.round((Number(modelData.activeS) || 0) / 60))
            valueColor: page.tones.main
        }
    }

    SectionLabel {
        //% "This week"
        text: qsTrId("id-this-week")
    }
    StatBlock {
        objectName: "exerciseTotalTime"
        //% "Total exercise time"
        caption: qsTrId("id-total-exercise-time")
        value: HealthText.durationText(Math.round(page.week.activeS / 60))
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "exerciseAzm"
        caption: qsTrId("id-azm")
        value: HealthText.number(page.week.azm)
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "exerciseCalories"
        //% "Calories"
        caption: qsTrId("id-calories")
        value: HealthText.number(Math.round(page.week.kcal))
        unit: qsTrId("id-unit-cal")
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "exerciseModerate"
        caption: qsTrId("id-zone-moderate")
        value: HealthText.durationText(Math.round(page.week.moderateS / 60))
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "exerciseVigorous"
        caption: qsTrId("id-zone-vigorous")
        value: HealthText.durationText(Math.round(page.week.vigorousS / 60))
        valueColor: page.tones.main
    }
    StatBlock {
        objectName: "exercisePeak"
        caption: qsTrId("id-zone-peak")
        value: HealthText.durationText(Math.round(page.week.peakS / 60))
        valueColor: page.tones.main
    }

    Label {
        width: parent.width
        topPadding: Theme.space.l
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodySmall"
        color: Theme.color.onSurfaceVariant
        text: qsTrId("id-for-more-data").arg(page.exerciseWord).arg(HealthText.phoneApp)
    }
}
