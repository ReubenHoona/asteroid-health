/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The start (src/main.qml) on the fixtures of make-fixtures.py: QQuickView makes main.qml at 0 x 0 and gives it
 * the window's size after it. The Today list is made once the app has its size, so it is laid out once, at the
 * screen's. The pages a card opens are made from their files when one is first opened, not with the app; they
 * are pushed as before: a metric page for its metric, the settings opening their step goal page, the Morning
 * Brief a card's page.
 */

import QtQuick
import QtTest

Item {
    id: root
    width: 384
    height: 384

    Rectangle { anchors.fill: parent; color: "black" }
    Item { id: host; anchors.fill: parent }

    TestCase {
        name: "HealthStart"
        when: windowShown

        property var app: null

        function cleanup() {
            if (app)
                app.destroy()
            app = null
            wait(50)
        }

        function typeName(o) {
            return String(o).replace(/_QML(TYPE)?_[0-9]+.*$/, "").replace(/\(0x.*$/, "")
        }

        function byName(item, name) {
            if (!item)
                return null
            if (item.objectName === name)
                return item
            var kids = item.children || []
            for (var i = 0; i < kids.length; i++) {
                var r = byName(kids[i], name)
                if (r)
                    return r
            }
            return null
        }

        function component() {
            var c = Qt.createComponent(Qt.resolvedUrl("../src/main.qml"))
            compare(c.status, Component.Ready, c.errorString())
            return c
        }

        // the page the stack shows, once its push is over
        function shownPage(stack) {
            wait(600)
            return stack.currentLayer
        }

        function test_today_made_at_the_apps_size() {
            app = component().createObject(null)
            verify(app !== null)
            compare(app.width, 0)
            var stack = byName(app, "pageStack")
            verify(stack)
            compare(stack.firstPageItem, undefined, "no Today list at 0 x 0")
            app.parent = host
            compare(app.width, 384)
            var page = stack.firstPageItem
            verify(page, "the Today list, made at the screen's size")
            compare(typeName(page), "TodayPage")
            compare(page.width, 384)
            compare(page.height, 384)
            compare(stack.layers.length, 0)
        }

        function test_pages_made_when_first_opened() {
            app = component().createObject(host, { width: 384, height: 384 })
            wait(300)
            var stack = byName(app, "pageStack")
            compare(Object.keys(app._components).length, 0, "no page made from its file at start")
            app.openStat("heartrate")
            compare(typeName(shownPage(stack)), "HeartrateDetailPage")
            compare(Object.keys(app._components).length, 1)
            // the five metric pages: one file, the page shows its metric
            app.openStat("floors")
            var p = shownPage(stack)
            compare(typeName(p), "MetricDetailPage")
            compare(p.metric, "floors")
            app.openStat("energy")
            compare(shownPage(stack).metric, "energy")
            compare(Object.keys(app._components).length, 2)
            compare(stack.layers.length, 3)
            compare(app.pageFor("goal"), null, "no card has the step goal's page")
            compare(app.pageFor("nothing"), null)
            compare(app.pageFor("constructor"), null, "an open request's key is one of the pages'")
        }

        function test_settings_and_brief_open_their_pages() {
            app = component().createObject(host, { width: 384, height: 384 })
            wait(300)
            var stack = byName(app, "pageStack")
            app.openStat("settings")
            var settings = shownPage(stack)
            compare(typeName(settings), "HealthSettingsPage")
            settings.pageRequested("goal")
            compare(typeName(shownPage(stack)), "StepGoalPage")
            compare(stack.layers.length, 2)
            app.openStat("morning")
            var brief = shownPage(stack)
            compare(typeName(brief), "MorningBriefPage")
            brief.statRequested("sleep")
            compare(typeName(shownPage(stack)), "SleepDetailPage")
            compare(stack.layers.length, 4)
        }
    }
}
