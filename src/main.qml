/*
 * Copyright (C) 2023 Arseniy Movshev <dodoradio@outlook.com>
 *               2026 eos
 *               2019 Florent Revest <revestflo@gmail.com>
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

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

import "data"
import "heartrate"
import "metrics"
import "morning"
import "settings"
import "sleep"
import "stepCounter"
import "today"

// The Health app as stock's Today list (health-fitness-02): the main goal ring and one card per metric on
// a black page (no FlatMesh, health-fitness-20); a card opens its detail page, the last row the settings.
Application {
    id: app

    LayerStack {
        id: pageStack
        objectName: "pageStack"
        anchors.fill: parent
        firstPage: Component {
            TodayPage {
                onOpened: (key) => app.openStat(key)
            }
        }
    }

    Component { id: stepsPage; StepsDetailPage {} }
    Component { id: heartratePage; HeartrateDetailPage {} }
    Component { id: restingPage; RestingHeartRatePage {} }
    Component { id: sleepPage; SleepDetailPage {} }
    Component { id: energyPage; MetricDetailPage { metric: "energy" } }
    Component { id: distancePage; MetricDetailPage { metric: "distance" } }
    Component { id: floorsPage; MetricDetailPage { metric: "floors" } }
    Component { id: azmPage; MetricDetailPage { metric: "azm" } }
    Component { id: hourlyPage; MetricDetailPage { metric: "hourly" } }
    Component {
        id: morningPage
        MorningBriefPage {
            onStatRequested: (key) => app.openStat(key)
        }
    }
    Component {
        id: settingsPage
        HealthSettingsPage {
            onPageRequested: (name) => pageStack.push(stepGoalPage)
        }
    }
    Component { id: stepGoalPage; StepGoalPage {} }

    // the page of a card: "steps", "energy", "distance", "floors", "azm", "hourly", "heartrate",
    // "resting", "sleep"; and "settings", "morning"
    function pageFor(key) {
        switch (key) {
        case "steps": return stepsPage
        case "energy": return energyPage
        case "distance": return distancePage
        case "floors": return floorsPage
        case "azm": return azmPage
        case "hourly": return hourlyPage
        case "heartrate": return heartratePage
        case "resting": return restingPage
        case "sleep": return sleepPage
        case "settings": return settingsPage
        case "morning": return morningPage
        }
        return null
    }

    function openStat(key) {
        var page = pageFor(key)
        if (page)
            pageStack.push(page)
    }

    // The launcher's tiles and the notifications open a page of this app: before they launch (or raise) it
    // they set this key to "<page>@<time in ms>" (the heart rate tile: "heartrate", the Morning Brief
    // notification: "morning"; any card's key works)
    ConfigurationValue {
        id: openRequest
        key: "/org/asteroidos/health/ui/open"
        defaultValue: ""
        onValueChanged: Qt.callLater(app.openRequested)
    }
    function openRequested() {
        var request = String(openRequest.value || "")
        if (request === "")
            return
        openRequest.value = ""
        var at = request.lastIndexOf("@")
        var age = Date.now() - Number(request.substring(at + 1))
        // an old request (the app started later some other way): ignored
        if (at < 0 || !(age > -5000 && age < 60000))
            return
        var key = request.substring(0, at)
        if (pageFor(key) === null)
            return
        while (pageStack.layers.length > 0)
            pageStack.pop(pageStack.currentLayer)
        pageStack.push(pageFor(key))
    }
    Component.onCompleted: Qt.callLater(openRequested)
}
