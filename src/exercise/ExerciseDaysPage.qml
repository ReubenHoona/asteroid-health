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

    // Stock's head of the page is the Exercise card's model (ExerciseDetailsViewModel via ync.java:253-257 i(): the
    // cardio icon in vhv(icon, s(done, goal)), a ring of segments: one a day of the goal, the days done first and
    // filled, more segments when the days done pass the goal: s() at ync.java:85-96). It has no row of the week's day
    // letters: a row of seven was ~305 px wide and the round screen cut its ends; the ring is 56 dp and fits wherever
    // the page scrolls it
    Item {
        id: ring
        objectName: "exerciseWeekRing"
        readonly property int done: page.week.done
        // s(): the days done, then the goal's days still to go
        readonly property int segments: Math.max(Format.EXERCISE_DAYS_GOAL, done)
        // the gap between two segments, degrees (Wear's segmented progress: about a stroke's width)
        readonly property real gap: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.dp(56)
        height: width
        Repeater {
            model: ring.segments
            delegate: ProgressArc {
                id: segment
                required property int index
                readonly property bool done: segment.index < ring.done
                objectName: "exerciseSegment" + segment.index
                anchors.fill: parent
                strokeWidth: Theme.dp(4)
                startAngle: 270 + segment.index * 360 / ring.segments + ring.gap / 2
                sweepAngle: 360 / ring.segments - ring.gap
                color: segment.done ? page.tones.main : HealthPalette.track
            }
        }
        Icon {
            anchors.centerIn: parent
            width: Theme.size.iconSmall
            height: width
            name: "eos-exercise"
            color: page.tones.main
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
