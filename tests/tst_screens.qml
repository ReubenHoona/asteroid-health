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

        // every text fully inside the screen's height: inside the circle (not
        // while scrolling: overlapOnly), and over no other text
        function checkTexts(page, name, overlapOnly) {
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
                if (r.y < 0 || r.y + r.h > 384) {
                    // partly off the screen: still never over another text
                    if (overlapOnly && r.y + r.h > 0 && r.y < 384)
                        rects.push(r)
                    continue
                }
                // the glyphs leave some room at the top and bottom of the line
                var inset = r.h * 0.2
                var corners = [[r.x, r.y + inset], [r.x + r.w, r.y + inset], [r.x, r.y + r.h - inset], [r.x + r.w, r.y + r.h - inset]]
                for (var c = 0; c < (overlapOnly ? 0 : 4); c++) {
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

        // a finger drag up (dy < 0) or down of about 290 px over 500 ms, as on
        // the watch; halfway: no text over another (mid-scroll), shot midName
        function fingerDrag(root, dy, midName) {
            var x = 192, y = dy < 0 ? 300 : 84
            mousePress(screen, x, y)
            for (var i = 1; i <= 15; i++) {
                mouseMove(screen, x, y + dy * i / 15, 33, Qt.LeftButton)
                if (i === 8 && midName) {
                    checkTexts(root, midName, true)
                    shot(midName)
                }
            }
            mouseRelease(screen, x, y + dy)
        }

        // crown detents (RotaryInput: 24 counts of 120 each): > 0 down the page
        function crown(detents) {
            for (var i = 0; i < Math.abs(detents); i++) {
                mouseWheel(screen, 192, 192, 0, detents > 0 ? -2880 : 2880)
                wait(60)
            }
        }

        // the page comes to rest on section i
        function settlesOn(flick, i, what) {
            wait(600)
            var ys = flick.stops()
            compare(flick.current, i, what + ": section")
            compare(Math.round(flick.contentY), Math.round(ys[i]), what + ": contentY " + flick.contentY + " stops " + ys)
        }

        // each screen of the page at rest, reached by finger drags (one section
        // each) and back by the crown: the top, the day chart, the week
        function screens(page, prefix) {
            var flick = find(page, "SectionFlickable")
            verify(flick)
            flick.snapTo(0, false)
            wait(50)
            verify(checkTexts(page, prefix + "-top") > 2)
            shot(prefix + "-top")
            var n = flick.stops().length
            var chart = find(page, "DayChart")
            var hasChart = chart && sectionOf(chart, flick).visible
            compare(n, hasChart ? 3 : 2)
            fingerDrag(page, -290, prefix + "-mid1")
            settlesOn(flick, 1, prefix + " drag 1")
            checkTexts(page, prefix + (hasChart ? "-chart" : "-week"))
            shot(prefix + (hasChart ? "-chart" : "-week"))
            if (hasChart) {
                fingerDrag(page, -290, prefix + "-mid2")
                settlesOn(flick, 2, prefix + " drag 2")
                checkTexts(page, prefix + "-week")
                shot(prefix + "-week")
                // past the end: stays on the week
                fingerDrag(page, -290)
                settlesOn(flick, 2, prefix + " drag past the end")
            }
            // the crown: one detent goes back to where it was, two go a section
            crown(-1)
            settlesOn(flick, n - 1, prefix + " crown 1 detent")
            crown(-2)
            settlesOn(flick, n - 2, prefix + " crown 2 detents")
            if (hasChart) {
                // a short drag goes back to the section it started from
                fingerDrag(page, -90)
                settlesOn(flick, 1, prefix + " short drag")
                crown(-2)
                settlesOn(flick, 0, prefix + " crown to the top")
            }
            // a drag down at the top stays there
            fingerDrag(page, 290)
            settlesOn(flick, 0, prefix + " drag down at the top")
        }

        // a sideways swipe across the day at a glance
        function swipeDay(page, right) {
            var area = find(page, "DaySwipeArea")
            verify(area.children[0].blocksBackSwipe)
            mouseDrag(area, right ? 100 : 280, 250, right ? 180 : -180, 0, Qt.LeftButton, Qt.NoModifier, 30)
            wait(400)
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

            // on the chart screen, a swipe to a day without a chart: the page
            // goes to the glance of that day
            var flick = find(page, "SectionFlickable")
            fingerDrag(page, -290)
            settlesOn(flick, 1, "chart of yesterday")
            mouseDrag(screen, 100, 192, 180, 0, Qt.LeftButton, Qt.NoModifier, 30)   // today-2: not worn
            wait(400)
            compare(page.day.count, 0)
            settlesOn(flick, 0, "no chart: the glance")
            checkTexts(page, "hr-nodata")
            shot("hr-nodata-top")
            screens(page, "hr-nodata")

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

        // the Overview scrolls freely; its title goes with it and nothing is
        // ever drawn over it
        function test_5_overviewScroll() {
            startApp()
            var stack = find(app, "LayerStack")
            var flick = flickableOf(find(app, "StepCounterPreview"))
            var title = find(app, "PageHeader")
            compare(flick.contentY, 0)
            fingerDrag(stack, -290, "overview-mid1")
            wait(800)
            verify(flick.contentY > 100)
            verify(title.mapToItem(screen, 0, 0).y < -100)
            checkTexts(stack, "overview-scrolled", true)
            shot("overview-scrolled")
            fingerDrag(stack, -290, "overview-mid2")
            wait(800)
            checkTexts(stack, "overview-scrolled2", true)
            shot("overview-scrolled2")
        }

        // a quick short fling goes a section on; a long fast crown turn
        // scrolls on and still comes to rest on a section
        function test_6_flingAndCrown() {
            startApp()
            var page = openFromOverview("HeartratePreview", "HeartrateDetailPage")
            var flick = find(page, "SectionFlickable")
            mousePress(screen, 192, 300)
            for (var i = 1; i <= 4; i++)
                mouseMove(screen, 192, 300 - 30 * i, 16, Qt.LeftButton)
            mouseRelease(screen, 192, 180)
            settlesOn(flick, 1, "quick fling")
            flick.snapTo(0, false)
            crown(8)
            wait(600)
            var ys = flick.stops()
            verify(flick.current > 0, "a long crown turn moves on")
            compare(Math.round(flick.contentY), Math.round(ys[flick.current]), "rests on a section")
            crown(-8)
            settlesOn(flick, 0, "and back")
        }

        // the other pages with a title: it is in their Flickable and scrolls
        // away with the page
        function test_7_titlesScroll() {
            startApp()
            var stack = find(app, "LayerStack")
            var overview = flickableOf(find(app, "StepCounterPreview"))
            overview.contentY = overview.contentHeight - overview.height
            wait(300)
            var items = findAll(app, function(o) { return o.title === "Settings" && o.clicked !== undefined })
            compare(items.length, 1)
            mouseClick(items[0])
            var pages = ["RootSettingsPage", "UiSettingsPage", "LoggerSettingsPage"]
            var titles = ["UI settings", "Logger settings"]
            for (var i = 0; i < pages.length; i++) {
                var page = currentPage(pages[i])
                var header = find(page, "PageHeader")
                var flick = find(page, "QQuickFlickable")
                verify(header && flick, pages[i])
                compare(header.parent, flick.contentItem, pages[i] + ": the title scrolls with the page")
                checkTexts(page, pages[i])
                shot("title-" + pages[i])
                if (i === 0) {
                    var open = findAll(page, function(o) { return o.title === titles[0] && o.clicked !== undefined })
                    mouseClick(open[0])
                } else if (i === 1) {
                    stack.pop(stack.currentLayer)
                    wait(500)
                    var open2 = findAll(stack.currentLayer, function(o) { return o.title === titles[1] && o.clicked !== undefined })
                    mouseClick(open2[0])
                }
            }
            // the rest compile (the weight page is off by default)
            var urls = ["../src/weight/WeightDetailPage.qml", "../src/SettingsPage.qml"]
            for (var u = 0; u < urls.length; u++) {
                var c = Qt.createComponent(Qt.resolvedUrl(urls[u]))
                compare(c.status, Component.Ready, urls[u] + " " + c.errorString())
            }
        }

        // the launcher's heart rate tile: a recent request opens the heart
        // rate page on today (also over another page), an old one does not
        function test_8_openRequest() {
            startApp()
            var stack = find(app, "LayerStack")
            var request = null
            for (var i = 0; i < app.resources.length; i++)
                if (app.resources[i].key === "/org/asteroidos/health/ui/open")
                    request = app.resources[i]
            verify(request, "the request key")
            request.value = "heartrate@" + Date.now()
            var page = currentPage("HeartrateDetailPage")
            compare(find(page, "DayNavigator").dayName(page.currentDay), "Today")
            tryCompare(request, "value", "")
            tapArrow(page, true)
            request.value = "heartrate@" + Date.now()
            wait(300)
            page = currentPage("HeartrateDetailPage")
            compare(stack.layers.length, 1)
            compare(find(page, "DayNavigator").dayName(page.currentDay), "Today")
            stack.pop(stack.currentLayer)
            request.value = "heartrate@" + (Date.now() - 120000)
            wait(600)
            compare(stack.layers.length, 0)
            request.value = "steps@" + Date.now()
            wait(600)
            compare(stack.layers.length, 0)
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
