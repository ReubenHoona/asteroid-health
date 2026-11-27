/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

import "../data"
import "../data/HealthStats.js" as Stats
import "../data/HealthFormat.js" as Format
import "../theme"
import "../ui"

// Morning Brief (health-fitness-26, stock MorningBriefActivity): what the notification 'Start your day'
// opens when Bedtime mode ends in the morning, or when sensorlogd has the night of a morning without Bedtime (R5
// E-10, its wake-up), and the Today list's Morning Brief card. Stock's pages in its order (MorningBriefPagesOrder:
// landing, sleep, exercise, weather, outro; readiness, the health metrics and activity plans are not on this
// watch): the landing (the sun, 'Good morning! Here's how your day is shaping up.'), last night's sleep, the
// exercise (yesterday's steps with their distance, this week's exercise days), today's weather from the Weather
// app's data (the condition, the high and the low) and the outro (one of stock's five lines a day). A card is left
// out when it has nothing to say.
HealthPage {
    id: page
    readonly property date today: HealthData.today
    readonly property var night: { HealthData.version; return HealthData.sleep() }
    readonly property date yesterday: Stats.addDays(today, -1)
    readonly property int yesterdaySteps: { HealthData.version; return HealthData.stepsOf(page.yesterday) }
    readonly property var yesterdaySummary: { HealthData.version; return HealthData.summary(page.yesterday) }
    // the weather of today, in kelvin as the Weather app keeps it (0: none has arrived)
    readonly property bool hasWeather: weatherMax.value > 200 && weatherMin.value > 200
    readonly property bool fahrenheit: useFahrenheit.value === true

    //% "Morning Brief"
    title: qsTrId("id-morning-brief")

    ConfigurationValue { id: weatherId; key: "/org/asteroidos/weather/day0/id"; defaultValue: 0 }
    ConfigurationValue { id: weatherMax; key: "/org/asteroidos/weather/day0/max-temp"; defaultValue: 0 }
    ConfigurationValue { id: weatherMin; key: "/org/asteroidos/weather/day0/min-temp"; defaultValue: 0 }
    ConfigurationValue { id: weatherCity; key: "/org/asteroidos/weather/city-name"; defaultValue: "" }
    ConfigurationValue { id: useFahrenheit; key: "/org/asteroidos/settings/use-fahrenheit"; defaultValue: false }

    // the landing page
    Icon {
        objectName: "briefLanding"
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.size.iconSmall * 1.5
        height: width
        name: "ios-sunny"
        color: HealthPalette.wellness.main
    }
    Label {
        objectName: "greeting"
        // inside the round screen under the landing's sun
        width: parent.width * 0.84
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodyLarge"
        color: Theme.color.onSurface
        //% "Good morning! Here’s how your day is shaping up."
        text: qsTrId("id-morning-greeting")
    }

    // last night
    MetricCard {
        objectName: "briefSleep"
        width: page.contentWidth
        title: qsTrId("id-sleep")
        iconName: "eos-health-sleep"
        category: "wellness"
        textValue: true
        value: page.night.valid ? HealthText.durationText(page.night.main.asleepMin) : HealthText.none
        subtitle: page.night.valid ? (page.night.scoreLabel || "") : qsTrId("id-wear-to-sleep")
        onClicked: page.openStat("sleep")
    }

    // the exercise page: yesterday's steps and this week's exercise days
    MetricCard {
        objectName: "briefSteps"
        width: page.contentWidth
        //% "Yesterday"
        title: qsTrId("id-yesterday")
        iconName: "eos-health-steps"
        category: "fitness"
        value: HealthText.number(page.yesterdaySteps)
        //% "steps"
        unit: qsTrId("id-unit-steps")
        subtitle: page.yesterdaySteps > 0 ? HealthText.distanceText(page.yesterdaySummary.distanceM) : ""
        onClicked: page.openStat("steps")
    }
    MetricCard {
        objectName: "briefExercise"
        readonly property var week: { HealthData.version; return Format.exerciseWeek(HealthData.weekWorkouts(page.today), Format.weekStartMs(page.today.getTime())) }
        width: page.contentWidth
        title: qsTrId("id-exercise-days")
        iconName: "eos-exercise"
        category: "fitness"
        value: String(week.done)
        subtitle: qsTrId("id-exercise-days-week").arg(week.done).arg(Format.EXERCISE_DAYS_GOAL)
        onClicked: page.openStat("exercise")
    }

    // the weather
    MetricCard {
        objectName: "briefWeather"
        width: page.contentWidth
        visible: page.hasWeather
        title: weatherCity.value !== "" ? String(weatherCity.value) :
            //% "Weather"
            qsTrId("id-weather")
        iconName: Format.weatherIcon(weatherId.value)
        category: "health"
        textValue: true
        value: Format.temperature(weatherMax.value, page.fahrenheit) + "° / " + Format.temperature(weatherMin.value, page.fahrenheit) + "°"
    }

    // the outro
    Label {
        objectName: "briefOutro"
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        role: "bodyLarge"
        color: Theme.color.onSurface
        text: HealthText.outroText(page.today)
    }

    // the Health app opens the stat the brief's card names
    signal statRequested(string key)
    function openStat(key) {
        statRequested(key)
    }
}
