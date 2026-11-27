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

import "today"

// The Health app as stock's Today list (health-fitness-02): the main goal ring and one card per metric on
// a black page (no FlatMesh, health-fitness-20); a card opens its detail page, the last row the settings.
Application {
    id: app

    // The Today list is made once the app has its size (makeToday()): main.qml is made at 0 x 0 and gets
    // the window's size after it, so a list made with the app was laid out at 0 x 0 and again at full size.
    LayerStack {
        id: pageStack
        objectName: "pageStack"
        anchors.fill: parent
    }
    Component {
        id: todayComponent
        TodayPage {
            onOpened: (key) => app.openStat(key)
        }
    }
    property bool todayMade: false
    function makeToday() {
        if (todayMade || width <= 0)
            return
        todayMade = true
        pageStack.firstPage = todayComponent
    }
    onWidthChanged: makeToday()

    // The page of a card by key, and the "settings" and "morning" pages: made from their files when one is
    // first opened (pageFor()). As Components of this file their types (the charts, the heart rate page's
    // QtSensors) were loaded with the app, before the first frame.
    readonly property var pageFiles: ({
        "steps": "stepCounter/StepsDetailPage.qml",
        "energy": "metrics/MetricDetailPage.qml",
        "distance": "metrics/MetricDetailPage.qml",
        "floors": "metrics/MetricDetailPage.qml",
        "azm": "metrics/MetricDetailPage.qml",
        "exercise": "exercise/ExerciseDaysPage.qml",
        "hourly": "metrics/MetricDetailPage.qml",
        "heartrate": "heartrate/HeartrateDetailPage.qml",
        "resting": "heartrate/RestingHeartRatePage.qml",
        "sleep": "sleep/SleepDetailPage.qml",
        "skintemp": "skintemp/SkinTempPage.qml",
        "cardioload": "cardioload/CardioLoadPage.qml",
        "settings": "settings/HealthSettingsPage.qml",
        "morning": "morning/MorningBriefPage.qml"
    })
    readonly property string stepGoalFile: "settings/StepGoalPage.qml"
    property var _components: ({})
    function _component(file) {
        if (_components[file] === undefined)
            _components[file] = Qt.createComponent(Qt.resolvedUrl(file))
        return _components[file]
    }

    // the page of a card: "steps", "energy", "distance", "floors", "azm", "exercise", "hourly", "heartrate",
    // "resting", "sleep"; and "settings", "morning"
    function pageFor(key) {
        return pageFiles.hasOwnProperty(key) ? _component(pageFiles[key]) : null
    }

    // a metric page shows its metric; the Morning Brief opens a card's page, the settings their step goal
    function openStat(key) {
        var page = pageFor(key)
        if (!page)
            return
        var layer = pageStack.push(page, pageFiles[key] === "metrics/MetricDetailPage.qml" ? { "metric": key } : {})
        if (layer && key === "morning")
            layer.statRequested.connect(app.openStat)
        else if (layer && key === "settings")
            layer.pageRequested.connect(function (name) { pageStack.push(app._component(app.stepGoalFile)) })
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
        openStat(key)
    }
    Component.onCompleted: {
        makeToday()
        Qt.callLater(openRequested)
    }
}
