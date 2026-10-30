/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The real main.qml on the fixtures of make-fixtures.py, 384x384 (a round
 * screen): taps and swipes through the heart rate and steps pages, a
 * screenshot of each screen in /tmp/healthui-shots (with the round edge
 * drawn in; the runner moves them) and, on every screen, a check that no text is cut off by the round
 * edge or drawn over other text.
 */

import QtQuick
import QtTest

Item {
    width: 384
    height: 384

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        id: screen
        width: 384
        height: 384
        clip: true
        Item { id: host; anchors.fill: parent }
        // the round display: what is outside it is never seen
        Canvas {
            anchors.fill: parent
            z: 100
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = "#000000"
                ctx.beginPath()
                ctx.rect(0, 0, width, height)
                ctx.arc(width / 2, height / 2, width / 2, 0, 2 * Math.PI, true)
                ctx.fill()
                ctx.strokeStyle = "#555555"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, width / 2 - 0.5, 0, 2 * Math.PI)
                ctx.stroke()
            }
        }
    }

    TestCase {
        name: "HealthScreens"
        when: windowShown

        property string shots: "/tmp/healthui-shots"
        property var app: null
        // what checkTexts found wrong on the screens of the running test
        property var problems: []

        function typeName(o) {
            return String(o).replace(/_QML(TYPE)?_[0-9]+.*$/, "").replace(/\(0x.*$/, "")
        }

        function find(item, name) {
            if (!item)
                return null
            if (typeName(item) === name)
                return item
            var kids = item.children || []
            for (var i = 0; i < kids.length; i++) {
                var r = find(kids[i], name)
                if (r)
                    return r
            }
            return null
        }

        function findAll(item, pred, out) {
            out = out || []
            if (!item)
                return out
            if (pred(item))
                out.push(item)
            var kids = item.children || []
            for (var i = 0; i < kids.length; i++)
                findAll(kids[i], pred, out)
            return out
        }

        function visibleOnScreen(item) {
            for (var p = item; p; p = p.parent) {
                if (!p.visible || p.opacity === 0)
                    return false
                if (p === screen)
                    return true
            }
            return false
        }

        function flickableOf(item) {
            for (var p = item; p; p = p.parent)
                if (typeName(p) === "QQuickFlickable" || (p.contentY !== undefined && p.contentHeight !== undefined && p.flickableDirection !== undefined))
                    return p
            return null
        }

        function shot(name) {
            wait(250)
            var img = grabImage(screen)
            if (shots)
                img.save(shots + "/" + name + ".png")
        }

        // every text fully inside the screen's height: inside the circle, and
        // over no other text
        function checkTexts(page, name) {
            var texts = findAll(page, function(o) {
                return o.text !== undefined && o.contentWidth !== undefined && typeof o.text === "string"
                        && o.text.length > 0 && visibleOnScreen(o)
            })
            var rects = []
            for (var i = 0; i < texts.length; i++) {
                var t = texts[i]
                var dx = t.horizontalAlignment === Text.AlignHCenter ? (t.width - t.contentWidth) / 2 :
                         t.horizontalAlignment === Text.AlignRight ? t.width - t.contentWidth : 0
                var dy = t.verticalAlignment === Text.AlignVCenter ? (t.height - t.contentHeight) / 2 :
                         t.verticalAlignment === Text.AlignBottom ? t.height - t.contentHeight : 0
                var p = t.mapToItem(screen, dx, dy)
                var r = { x: p.x, y: p.y, w: Math.min(t.contentWidth, t.width > 0 ? t.width : t.contentWidth), h: t.contentHeight, text: t.text }
                if (r.y < 0 || r.y + r.h > 384)
                    continue
                // the glyphs leave some room at the top and bottom of the line
                var inset = r.h * 0.2
                var corners = [[r.x, r.y + inset], [r.x + r.w, r.y + inset], [r.x, r.y + r.h - inset], [r.x + r.w, r.y + r.h - inset]]
                for (var c = 0; c < 4; c++) {
                    var ddx = corners[c][0] - 192
                    var ddy = corners[c][1] - 192
                    if (ddx * ddx + ddy * ddy > 190 * 190) {
                        problems.push(name + ": \"" + r.text + "\" is cut by the round edge at " + Math.round(corners[c][0]) + "," + Math.round(corners[c][1]))
                        break
                    }
                }
                rects.push(r)
            }
            for (var a = 0; a < rects.length; a++)
                for (var b = a + 1; b < rects.length; b++) {
                    var A = rects[a], B = rects[b]
                    var ox = Math.min(A.x + A.w, B.x + B.w) - Math.max(A.x, B.x)
                    var oy = Math.min(A.y + A.h, B.y + B.h) - Math.max(A.y, B.y)
                    if (ox > 1 && oy > 2)
                        problems.push(name + ": \"" + A.text + "\" overlaps \"" + B.text + "\"")
                }
            return rects.length
        }

        function scrollTo(flick, y) {
            flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height))
            wait(50)
        }

        function init() {
            problems = []
        }

        function cleanup() {
            compare(problems.join("; "), "")
        }

        function startApp() {
            if (app)
                app.destroy()
            wait(50)
            var c = Qt.createComponent(Qt.resolvedUrl("../src/main.qml"))
            compare(c.status, Component.Ready, c.errorString())
            app = c.createObject(host, { width: 384, height: 384 })
            verify(app)
            wait(300)
        }

        function currentPage(name) {
            var stack = find(app, "LayerStack")
            verify(stack)
            tryVerify(function() { return stack.layers.length > 0 }, 2000)
            wait(500) // the push animation
            var page = stack.currentLayer
            compare(typeName(page), name)
            return page
        }

        function openFromOverview(previewName, pageName) {
            var preview = find(app, previewName)
            verify(preview, previewName)
            var flick = flickableOf(preview)
            scrollTo(flick, preview.mapToItem(flick.contentItem, 0, 0).y - 100)
            shot("overview-" + (pageName === "HeartrateDetailPage" ? "heartrate" : "steps"))
            mouseClick(preview, preview.width / 2, Math.min(preview.height - 5, 60))
            return currentPage(pageName)
        }

        // the screen (a section of the page's column) holding item
        function sectionOf(item, flick) {
            var p = item
            while (p.parent && p.parent.parent !== flick.contentItem)
                p = p.parent
            return p
        }

        // each screen of the page at rest: the top, the day chart, the week
        function screens(page, prefix) {
            var flick = find(page, "QQuickFlickable")
            verify(flick)
            scrollTo(flick, 0)
            verify(checkTexts(page, prefix + "-top") > 2)
            shot(prefix + "-top")
            var chart = find(page, "DayChart")
            if (chart && sectionOf(chart, flick).visible) {
                scrollTo(flick, sectionOf(chart, flick).y)
                checkTexts(page, prefix + "-chart")
                shot(prefix + "-chart")
            }
            var week = find(page, "WeekChart")
            scrollTo(flick, sectionOf(week, flick).y)
            compare(flick.contentY, sectionOf(week, flick).y)
            checkTexts(page, prefix + "-week")
            shot(prefix + "-week")
            scrollTo(flick, 0)
        }

        // a sideways swipe across the day at a glance
        function swipeDay(page, right) {
            var area = find(page, "DaySwipeArea")
            verify(area.children[0].blocksBackSwipe)
            mouseDrag(area, right ? 100 : 280, 250, right ? 180 : -180, 0, Qt.LeftButton, Qt.NoModifier, 30)
            wait(300)
        }

        function tapArrow(page, back) {
            var nav = find(page, "DayNavigator")
            var arrow = nav.children[back ? 0 : 2]
            mouseClick(arrow)
            wait(250)
        }

        function test_1_heartrate() {
            startApp()
            shot("overview")
            var page = openFromOverview("HeartratePreview", "HeartrateDetailPage")
            compare(page.day.latest, 100)
            verify(page.day.resting > 0)
            screens(page, "hr-today")

            swipeDay(page, true)     // a swipe right: yesterday
            compare(find(page, "DayNavigator").dayName(page.currentDay), "Yesterday")
            verify(page.day.count > 100)
            screens(page, "hr-yesterday")

            tapArrow(page, true)     // today-2: not worn
            compare(page.day.count, 0)
            checkTexts(page, "hr-nodata")
            shot("hr-nodata-top")

            tapArrow(page, true)     // today-3: the file with malformed lines
            compare(page.day.count, 48)
            checkTexts(page, "hr-malformed")
            shot("hr-malformed-top")

            tapArrow(page, true)     // today-4: one reading
            compare(page.day.count, 1)
            compare(page.day.latest, 77)
            screens(page, "hr-single")

            // a week further back: the week chart moves with the day
            for (var i = 0; i < 3; i++)
                tapArrow(page, true)
            compare(page.weekSelected, 6)
            compare(page.day.count, 0)
            screens(page, "hr-older")

            // a swipe left goes forward again, never past today
            for (var j = 0; j < 9; j++)
                swipeDay(page, false)
            compare(find(page, "DayNavigator").dayName(page.currentDay), "Today")
            verify(!find(page, "DayNavigator").canGoNext)
        }

        function test_2_steps() {
            startApp()
            var page = openFromOverview("StepCounterPreview", "StepsDetailPage")
            verify(page.dayTotal > 0)
            compare(page.goal, 8000)
            screens(page, "steps-today")

            tapArrow(page, true)
            verify(page.dayTotal > 8000)
            screens(page, "steps-yesterday")

            swipeDay(page, true)     // today-2: no data
            compare(page.day.count, 0)
            compare(page.week[4].hasData, false)
            checkTexts(page, "steps-nodata")
            shot("steps-nodata-top")

            for (var i = 0; i < 3; i++)
                swipeDay(page, true) // today-5: goal reached
            verify(page.dayTotal >= 8000)
            screens(page, "steps-goal")
        }

        // a swipe right across the day is the day before, from the left
        // edge it is still the back swipe
        function test_4_backSwipe() {
            startApp()
            var page = openFromOverview("HeartratePreview", "HeartrateDetailPage")
            var stack = find(app, "LayerStack")
            swipeDay(page, true)
            compare(stack.layers.length, 1)
            compare(find(page, "DayNavigator").dayName(page.currentDay), "Yesterday")
            mouseDrag(screen, 6, 192, 260, 0, Qt.LeftButton, Qt.NoModifier, 30)
            tryCompare(stack, "layers", [], 3000)
        }

        function test_3_overviewWeekTap() {
            startApp()
            var preview = find(app, "StepCounterPreview")
            var week = find(preview, "WeekChart")
            compare(week.days.length, 7)
            compare(week.days[4].hasData, false)   // today-2 keeps its place
            var flick = flickableOf(preview)
            scrollTo(flick, week.mapToItem(flick.contentItem, 0, 0).y - 120)
            shot("overview-steps-week")
            mouseClick(week, week.gutter + week.slot * 5.5, week.height / 2)
            var page = currentPage("StepsDetailPage")
            compare(find(page, "DayNavigator").dayName(page.currentDay), "Yesterday")
            compare(page.weekSelected, 5)
        }
    }
}
