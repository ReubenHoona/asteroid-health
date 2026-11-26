/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The real main.qml on the fixtures of make-fixtures.py, 384x384 (a round screen): the Today list of
 * metric cards, every detail page, the settings, the open request of the launcher's tiles and the
 * Morning Brief; a screenshot of each screen in /tmp/w3hlth-shots (with the round edge drawn in) and,
 * on every screen, a check that no text is cut off by the round edge or drawn over other text.
 * Every number the gaps' changes name (stock's colours, sizes, wording, order) is an assertion.
 */

import QtQuick
import QtTest
import Nemo.Configuration
import org.asteroid.controls

import "../src/data"
import "../src/data/HealthStats.js" as Stats
import "../src/data/HealthFormat.js" as Format
import "../src/theme"

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

    ConfigurationValue { id: goalKey; key: "/org/asteroidos/ux/steps-goal"; defaultValue: 10000 }
    ConfigurationValue { id: use12h; key: "/org/asteroidos/settings/use-12h-format"; defaultValue: true }
    ConfigurationValue { id: openKey; key: "/org/asteroidos/health/ui/open"; defaultValue: "" }
    ConfigurationValue { id: devKey; key: "/org/asteroidos/settings/developer-options"; defaultValue: false }
    ConfigurationValue { id: pGender; key: "/org/asteroidos/health/profile/gender"; defaultValue: "" }
    ConfigurationValue { id: pHeight; key: "/org/asteroidos/health/profile/height-cm"; defaultValue: 0 }
    ConfigurationValue { id: pWeight; key: "/org/asteroidos/health/profile/weight-kg"; defaultValue: 0.0 }
    ConfigurationValue { id: pAge; key: "/org/asteroidos/health/profile/age"; defaultValue: 0 }
    ConfigurationValue { id: wId; key: "/org/asteroidos/weather/day0/id"; defaultValue: 0 }
    ConfigurationValue { id: wMax; key: "/org/asteroidos/weather/day0/max-temp"; defaultValue: 0 }
    ConfigurationValue { id: wMin; key: "/org/asteroidos/weather/day0/min-temp"; defaultValue: 0 }
    ConfigurationValue { id: fahrenheit; key: "/org/asteroidos/settings/use-fahrenheit"; defaultValue: false }

    TestCase {
        name: "HealthScreens"
        when: windowShown

        property string shots: "/tmp/w3hlth-shots"
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

        function shot(name) {
            wait(250)
            var img = grabImage(screen)
            if (shots)
                img.save(shots + "/" + name + ".png")
        }

        // every text fully inside the screen's height: inside the circle (not while scrolling:
        // overlapOnly), and over no other text
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
                // a Label with a fixed line height reports a content height beyond its line box: what is
                // drawn is inside the item's height
                var h0 = Math.min(t.contentHeight, t.height > 0 ? t.height : t.contentHeight)
                var dy = t.verticalAlignment === Text.AlignVCenter ? (t.height - h0) / 2 :
                         t.verticalAlignment === Text.AlignBottom ? t.height - h0 : 0
                var p = t.mapToItem(screen, dx, dy)
                // the size as drawn: a row of a ScalingList is scaled towards the edges of the screen
                var w0 = Math.min(t.contentWidth, t.width > 0 ? t.width : t.contentWidth)
                var q = t.mapToItem(screen, dx + w0, dy + h0)
                var r = { x: p.x, y: p.y, w: q.x - p.x, h: q.y - p.y, text: t.text }
                if (r.y < 0 || r.y + r.h > 384) {
                    if (overlapOnly && r.y + r.h > 0 && r.y < 384)
                        rects.push(r)
                    continue
                }
                // a scrolling page runs on under the round edge at the top and the bottom (stock too): only
                // what is between the time text and the bottom 55 px must be inside the circle
                if (r.y < 52 || r.y + r.h > 330) {
                    rects.push(r)
                    continue
                }
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

        function init() {
            problems = []
            // a failed test leaves its page open: every test starts on the list
            if (app) {
                var s = byName(app, "pageStack")
                while (s && s.layers.length > 0) {
                    s.pop(s.currentLayer)
                    wait(600)
                }
            }
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

        function stack() {
            var s = byName(app, "pageStack")
            verify(s)
            return s
        }

        // the page the stack shows, once its transition is over
        function currentPage(name) {
            var s = stack()
            wait(600)
            var page = s.currentLayer
            if (name)
                compare(typeName(page), name)
            return page
        }

        function todayPage() {
            var p = find(app, "TodayPage")
            verify(p)
            return p
        }

        function texts(item) {
            return findAll(item, function(o) {
                return o.text !== undefined && typeof o.text === "string" && o.text !== "" && o.contentWidth !== undefined && visibleOnScreen(o)
            }).map(function(o) { return o.text })
        }

        function iconOf(item) {
            return find(item, "Icon")
        }

        function colorIs(c, hex) {
            compare(String(c).toLowerCase(), hex.toLowerCase())
        }

        // scroll the Today list so that the row of `key` is in view and return its index
        function rowItem(page, key) {
            var rows = page.rows
            var index = -1
            for (var i = 0; i < rows.length; i++)
                if (rows[i].key === key && rows[i].type !== "goal")
                    index = i
            verify(index >= 0, key)
            page.list.positionViewAtIndex(index, ListView.Center)
            wait(150)
            return index
        }

        function tapCard(page, key) {
            rowItem(page, key)
            var card = byName(page, key === "settings" ? "settingsRow" : "card-" + key)
            verify(card, "card " + key)
            mouseClick(card, card.width / 2, Math.min(card.height / 2, 30))
            wait(100)
        }

        // the page of the top layer, popped back to the list
        function back() {
            var s = stack()
            s.pop(s.currentLayer)
            wait(600)
        }

        function openCard(key, pageName) {
            var page = todayPage()
            tapCard(page, key)
            return currentPage(pageName)
        }

        function test_0_loads() {
            goalKey.value = 8000
            use12h.value = true
            pGender.value = "male"
            pHeight.value = 180
            pWeight.value = 75.0
            pAge.value = 40
            wait(400)
            startApp()
            var page = todayPage()
            compare(HealthData.stepGoal, 8000)
            compare(page.rows.length, 11)
            shot("today-top")
        }

        // health-fitness-02, -20, -23: the Today list
        function test_1_todayList() {
            var page = todayPage()
            var keys = page.rows.map(function(r) { return r.type + ":" + r.key })
            compare(keys.join(" "), "goal:steps card:steps card:energy card:distance card:floors card:azm card:hourly card:heartrate card:resting card:sleep settings:settings")
            var titles = page.rows.filter(function(r) { return r.type === "card" }).map(function(r) { return r.title })
            compare(titles.join("|"), "Steps|Energy burned|Distance|Floors|Active Zone Minutes|Hourly activity|Heart rate|Resting heart rate|Sleep")
            var steps = HealthData.stepsOf(HealthData.today)
            verify(steps > 1000)
            var r = page.rows
            // the main goal
            compare(r[0].value, HealthText.number(steps))
            compare(r[0].subtitle, HealthText.number(8000 - steps) + " left")
            verify(Math.abs(r[0].fraction - steps / 8000) < 1e-9)
            compare(r[1].value, HealthText.number(steps))
            var s = HealthData.summary(HealthData.today)
            compare(r[2].value, HealthText.number(Math.round(s.energyKcal)))
            compare(r[2].unit, "Cal")
            var imperial = HealthText.imperial
            compare(r[3].unit, imperial ? "mi" : "km")
            compare(r[3].value, (s.distanceM / (imperial ? 1609.344 : 1000)).toLocaleString(Qt.locale(), "f", 2))
            compare(r[4].value, "0")
            compare(r[5].value, String(s.azm))
            verify(s.azm > 0)
            compare(r[5].subtitle, HealthText.number(HealthData.azmWeek(HealthData.today)) + " of 150 this week")
            compare(r[6].value, String(s.hoursMet))
            compare(r[6].subtitle, s.hoursMet >= 9 ? "Completed today" : s.hoursMet + " of 9 hr")
            compare(r[7].value, "100")
            compare(r[7].unit, "bpm")
            compare(r[7].subtitle, "5 min ago")
            compare(r[8].value, "52")
            compare(r[9].value, "7 hr")
            compare(r[9].subtitle, "Good")
            compare(r[9].textValue, true)
            // stock's categories: FITNESS, HEALTH, WELLNESS (health-fitness-20)
            var cats = page.rows.filter(function(x) { return x.type === "card" }).map(function(x) { return x.category })
            compare(cats.join(" "), "fitness fitness fitness fitness fitness fitness health health wellness")
            // no 'Overview' sentence header, no 'Heartrate' preview: the list starts with the ring
            var all = texts(page)
            verify(all.indexOf("Overview") < 0)
            verify(all.indexOf("Heartrate") < 0)
            verify(all.length > 2)
            verify(checkTexts(page, "today-top") > 1)
            // black page: no mesh, the page colour is the theme's black (design-tokens-07)
            compare(app.meshBackground, false)
            colorIs(app.backgroundColor, "#000000")
        }

        function test_2_goalRing() {
            var page = todayPage()
            page.list.positionViewAtBeginning()
            wait(900)
            var arc = byName(page, "goalArc")
            verify(arc)
            var steps = HealthData.stepsOf(HealthData.today)
            // the ring has filled once (a spring), to the share of the goal, in the FITNESS colour
            verify(Math.abs(arc.sweepAngle - 360 * steps / 8000) < 0.5, "sweep " + arc.sweepAngle)
            colorIs(arc.color, "#43DCD0")
            var value = byName(page, "goalValue")
            colorIs(value.color, "#43DCD0")
            compare(value.text, HealthText.number(steps))
            var card = byName(page, "goalCard")
            verify(card.width > 300 && card.height > 200)
            // the ring rests: nothing animates while the list is still
            var moving = findAll(app, function(o) { return o.running === true && o.interval !== undefined })
            compare(moving.length, 0, "running timers: " + moving.length)
            shot("today-ring")
        }

        function test_3_cardColours() {
            var page = todayPage()
            var want = { steps: "#43DCD0", energy: "#43DCD0", distance: "#43DCD0", floors: "#43DCD0", azm: "#43DCD0",
                         hourly: "#43DCD0", heartrate: "#2BC7F7", resting: "#2BC7F7", sleep: "#D8B9FF" }
            for (var key in want) {
                rowItem(page, key)
                var card = byName(page, "card-" + key)
                verify(card, key)
                colorIs(iconOf(card).color, want[key])
                // the surface is the Material 3 card surface, never white or transparent
                colorIs(card.containerColor, "#2F3036")
                compare(card.width > 300, true)
            }
            colorIs(HealthPalette.fitness.main, "#43DCD0")
            colorIs(HealthPalette.fitness.mid, "#00867D")
            colorIs(HealthPalette.fitness.dark, "#00504B")
            colorIs(HealthPalette.fitness.deep, "#00201E")
            colorIs(HealthPalette.fitness.light, "#90F4EA")
            colorIs(HealthPalette.health.main, "#2BC7F7")
            colorIs(HealthPalette.health.mid, "#0081A8")
            colorIs(HealthPalette.health.dark, "#004D68")
            colorIs(HealthPalette.health.deep, "#001F2D")
            colorIs(HealthPalette.health.light, "#BDE9FF")
            colorIs(HealthPalette.wellness.main, "#D8B9FF")
            colorIs(HealthPalette.wellness.mid, "#8D62C5")
            colorIs(HealthPalette.wellness.dark, "#5A2F90")
            colorIs(HealthPalette.wellness.deep, "#290055")
            colorIs(HealthPalette.wellness.light, "#EDDCFF")
            colorIs(HealthPalette.tileHealth, "#94D6FF")
            colorIs(HealthPalette.tileFitness, "#80F7DD")
            colorIs(HealthPalette.tileWellness, "#E5C7FF")
            colorIs(HealthPalette.track, "#2D3130")
            colorIs(HealthPalette.label, "#BEC8C6")
            colorIs(HealthPalette.text, "#DADCE0")
        }

        function test_4_scrollList() {
            var page = todayPage()
            for (var i = 0; i < page.rows.length; i++) {
                page.list.positionViewAtIndex(i, ListView.Beginning)
                page.list.contentY -= 40
                wait(150)
                verify(checkTexts(page, "today-row" + i, true) > 0)
                if (i === 2 || i === 6 || i === 9 || i === 10)
                    shot("today-row" + i)
            }
        }

        // every card opens its page
        function test_5_cardsOpen() {
            var pages = { steps: "StepsDetailPage", energy: "MetricDetailPage", distance: "MetricDetailPage",
                          floors: "MetricDetailPage", azm: "MetricDetailPage", hourly: "MetricDetailPage",
                          heartrate: "HeartrateDetailPage", resting: "RestingHeartRatePage", sleep: "SleepDetailPage",
                          settings: "HealthSettingsPage" }
            for (var key in pages) {
                var page = openCard(key, pages[key])
                verify(checkTexts(page, "open-" + key) > 1, key)
                shot("open-" + key)
                back()
                compare(stack().layers.length, 0)
                verify(todayPage().visible)
            }
        }

        // the goal ring opens the steps page too
        function test_6_ringOpens() {
            var page = todayPage()
            page.list.positionViewAtBeginning()
            wait(200)
            var ring = byName(page, "goalCard")
            mouseClick(ring, ring.width / 2, ring.height / 2)
            currentPage("StepsDetailPage")
            back()
        }

        // the page at rest runs nothing: no repeating timer anywhere (battery, M1)
        function noTimers(page, what) {
            var running = findAll(page, function(o) { return o.running === true && o.interval !== undefined })
            compare(running.length, 0, what + ": running timers")
        }

        // bring an item of a HealthPage into the middle of the screen, then tap it
        function tapItem(page, item) {
            var y = item.mapToItem(page.flickable.contentItem, 0, 0).y
            page.flickable.contentY = Math.max(0, y - 150)
            wait(200)
            mouseClick(item, item.width / 2, Math.min(item.height / 2, 40))
            wait(300)
        }

        function dayOf(daysAgo) {
            return Stats.addDays(HealthData.today, -daysAgo)
        }

        // the chart labels of a day chart
        function axisLabels(chart) {
            return findAll(chart, function(o) {
                return o.role === "bodyExtraSmall" && typeof o.text === "string" && o.text !== "" && o.mapToItem(chart, 0, 0).y >= chart.plotHeight - 1
            }).sort(function(a, b) { return a.mapToItem(chart, 0, 0).x - b.mapToItem(chart, 0, 0).x }).map(function(o) { return o.text })
        }

        // health-fitness-09, -13, -25: the steps page
        function test_7_steps() {
            use12h.value = true
            wait(300)
            var page = openCard("steps", "StepsDetailPage")
            compare(page.title, "Steps")
            noTimers(page, "steps")
            var steps = HealthData.stepsOf(HealthData.today)
            var block = byName(page, "stepsToday")
            compare(block.valueLabel.text, HealthText.number(steps))
            compare(block.noteLabel.text, HealthText.number(8000 - steps) + " left")
            colorIs(block.valueLabel.color, "#43DCD0")
            // the best day and best hour of the week, found here from the summaries
            var bestSteps = 0, bestAgo = -1, hourSteps = 0, hourAgo = -1, hourAt = -1, sum = 0, n = 0
            for (var i = 6; i >= 0; i--) {
                var s = HealthData.summary(dayOf(i))
                if (s.steps > 0) {
                    sum += s.steps
                    n++
                }
                if (s.steps > 0 && s.steps >= bestSteps) {
                    bestSteps = s.steps
                    bestAgo = i
                }
                for (var h = 0; h < 24; h++)
                    if (s.hourSteps[h] > 0 && s.hourSteps[h] >= hourSteps) {
                        hourSteps = s.hourSteps[h]
                        hourAgo = i
                        hourAt = h
                    }
            }
            compare(bestAgo, 1 + 4)       // the 12,034 steps of the fifth day back
            verify(hourSteps > 0)
            var avg = byName(page, "stepsAverage")
            compare(avg.captionLabel.text, "Average steps")
            compare(avg.valueLabel.text, HealthText.number(Math.round(sum / n)))
            var bd = byName(page, "stepsBestDay")
            compare(bd.captionLabel.text, "Best day")
            compare(bd.valueLabel.text, HealthText.number(bestSteps))
            compare(bd.noteLabel.text, dayOf(bestAgo).toLocaleDateString(Qt.locale(), "dddd d MMM"))
            verify(bd.noteLabel.text.length > 4)
            var bh = byName(page, "stepsBestHour")
            compare(bh.captionLabel.text, "Best hour")
            compare(bh.valueLabel.text, HealthText.number(hourSteps))
            var hd = dayOf(hourAgo)
            compare(bh.noteLabel.text, TimeFormat.hour(new Date(hd.getFullYear(), hd.getMonth(), hd.getDate(), hourAt)))
            // the order: today, the day chart, the week, the average, the best day, the best hour
            var chart = byName(page, "stepsDayChart")
            var week = byName(page, "stepsWeekChart")
            var ys = [block, chart, week, avg, bd, bh].map(function(o) { return o.mapToItem(page.column, 0, 0).y })
            for (var k = 1; k < ys.length; k++)
                verify(ys[k] > ys[k - 1], "block order " + ys)
            // the week: 7 days, today's bar the bright one, the goal line at the goal (8,000)
            compare(week.days.length, 7)
            compare(week.selected, 6)
            compare(week.goal, 8000)
            verify(week.ticks[week.ticks.length - 1] >= bestSteps && bestSteps > 11000)
            colorIs(week.barColor, "#43DCD0")
            colorIs(chart.barColor, "#43DCD0")
            compare(chart.bars.length, 24)
            // the hour axis in the user's 12-hour format (health-fitness-13)
            var labels = axisLabels(chart)
            compare(labels.length, 4, "labels " + labels)
            verify(/^12\s?am$/i.test(labels[0]) && /^6\s?am$/i.test(labels[1]) && /^12\s?pm$/i.test(labels[2]) && /^6\s?pm$/i.test(labels[3]), "12 h " + labels)
            use12h.value = false
            wait(400)
            labels = axisLabels(chart)
            verify(/^0?0$/.test(labels[0]) && /^0?6$/.test(labels[1]) && /^12$/.test(labels[2]) && /^18$/.test(labels[3]), "24 h " + labels)
            compare(TimeFormat.hour(new Date(2026, 5, 1, 15)).replace(/^0/, ""), "15")
            use12h.value = true
            wait(400)
            labels = axisLabels(chart)
            verify(/^6\s?pm$/i.test(labels[3]), "12 h again " + labels)
            // no day arrows, no swipes between days: stock shows today and the week (health-fitness-25)
            compare(find(page, "DayNavigator"), null)
            compare(find(page, "DaySwipeArea"), null)
            shot("steps-top")
            page.flickable.contentY = chart.mapToItem(page.flickable.contentItem, 0, 0).y - 120
            wait(300)
            shot("steps-chart")
            checkTexts(page, "steps-chart", true)
            page.flickable.contentY = bd.mapToItem(page.flickable.contentItem, 0, 0).y - 120
            wait(300)
            shot("steps-best")
            checkTexts(page, "steps-best", true)
            // a swipe across the page is the back swipe, as everywhere in stock: it does not move to another day
            mouseDrag(screen, 100, 250, 180, 0, Qt.LeftButton, Qt.NoModifier, 30)
            wait(900)
            compare(stack().layers.length, 0)
            compare(HealthData.stepsOf(HealthData.today), steps)
        }

        // health-fitness-08, -13, -23: the heart rate page
        function test_8_heartRate() {
            var page = openCard("heartrate", "HeartrateDetailPage")
            compare(page.title, "Heart Rate")
            noTimers(page, "heart rate")
            var d = HealthData.heartDay(HealthData.today)
            // the sensor runs while the page is shown; here there is none: the latest logged reading
            compare(page.live, true)
            var bpm = byName(page, "bpmValue")
            compare(bpm.text, "100")
            colorIs(bpm.color, "#2BC7F7")
            compare(byName(page, "bpmNote").text, "5 min ago")
            page.liveBpm = 72
            compare(bpm.text, "72")
            compare(byName(page, "bpmNote").visible, false)
            page.liveBpm = 0
            compare(bpm.text, "100")
            var range = byName(page, "hrRange")
            compare(range.captionLabel.text, "Heart rate range")
            compare(range.valueLabel.text, d.min + " - " + d.max)
            compare(range.valueLabel.text, "49 - 150")
            compare(range.unit, "bpm")
            // the line chart of today: one reading a minute, 0..1 of the day, the HEALTH blue
            var chart = byName(page, "hrDayChart")
            verify(chart.points.length > 100)
            var px = chart.points.map(function(p) { return p.x })
            verify(px.every(function(x, i) { return x >= 0 && x <= 1 && (i === 0 || x > px[i - 1]) }), "points in time order")
            verify(chart.points.every(function(p) { return p.y >= 49 && p.y <= 150 }))
            colorIs(chart.lineColor, "#2BC7F7")
            compare(chart.bars.length, 0)
            // the zones: the minutes of today in each, and the zone note
            var s = HealthData.summary(HealthData.today)
            compare(byName(page, "zoneMinutes0").text, s.zoneLight + " min")
            compare(byName(page, "zoneMinutes1").text, s.zoneModerate + " min")
            compare(byName(page, "zoneMinutes2").text, s.zoneVigorous + " min")
            compare(byName(page, "zoneMinutes3").text, s.zonePeak + " min")
            // the workout (7:00-7:40, a reading a minute) is 11 minutes moderate and 30 vigorous for the profile
            compare(s.zoneModerate + ":" + s.zoneVigorous + ":" + s.zonePeak, "11:30:0")
            verify(s.zoneLight >= 50 && s.zoneLight <= 200, "light " + s.zoneLight)
            compare(byName(page, "zoneNote").text, "Heart rate zones based on age and your " + HealthData.metrics.restingHr() + " bpm RHR.")
            verify(HealthData.metrics.restingHr() >= 50 && HealthData.metrics.restingHr() <= 54)
            var all = texts(page)
            // the footer of stock
            var footer = byName(page, "hrFooter")
            compare(footer.text, "For more Heart rate data, open the Gadgetbridge mobile app")
            // the week's zones: 7 stacked bars
            var week = byName(page, "hrZoneWeek")
            compare(week.stacks.length, 7)
            compare(week.stacks[6][1].value, s.zoneModerate)
            colorIs(week.stacks[6][1].color, "#2BC7F7")
            // the old three screens and the day arrows are gone
            compare(find(page, "DayNavigator"), null)
            compare(find(page, "SectionFlickable"), null)
            // order: live value, range, line chart, zones, week, footer
            var ys = [bpm, range, chart, byName(page, "zoneRow0"), week, footer].map(function(o) { return o.mapToItem(page.column, 0, 0).y })
            for (var k = 1; k < ys.length; k++)
                verify(ys[k] > ys[k - 1], "block order " + ys)
            shot("hr-top")
            page.flickable.contentY = chart.mapToItem(page.flickable.contentItem, 0, 0).y - 150
            wait(300)
            shot("hr-chart")
            checkTexts(page, "hr-chart", true)
            page.flickable.contentY = byName(page, "zoneRow0").mapToItem(page.flickable.contentItem, 0, 0).y - 120
            wait(300)
            shot("hr-zones")
            checkTexts(page, "hr-zones", true)
            page.flickable.contentY = footer.mapToItem(page.flickable.contentItem, 0, 0).y - 200
            wait(300)
            shot("hr-week")
            back()
            // the sensor is only there while the page is
            compare(find(app, "HrmSensor"), null)
        }

        function test_9_resting() {
            var page = openCard("resting", "RestingHeartRatePage")
            compare(page.title, "Resting heart rate")
            noTimers(page, "resting")
            var sum = 0, n = 0
            for (var i = 6; i >= 0; i--) {
                var r = HealthData.heartDay(dayOf(i)).resting
                if (r > 0) {
                    sum += r
                    n++
                }
            }
            verify(n >= 3)
            compare(byName(page, "restingToday").valueLabel.text, "52")
            compare(byName(page, "restingToday").captionLabel.text, "Today")
            var avg = byName(page, "restingAverage")
            compare(avg.captionLabel.text, "Average resting HR")
            compare(avg.valueLabel.text, String(Math.round(sum / n)))
            compare(avg.noteLabel.text, "Last 7 days")
            colorIs(avg.valueLabel.color, "#2BC7F7")
            var week = byName(page, "restingWeek")
            compare(week.line, true)
            compare(week.days.length, 7)
            colorIs(week.markColor, "#2BC7F7")
            shot("resting")
            back()
        }

        // the cards that share a page
        function test_a_metricPages() {
            var s = HealthData.summary(HealthData.today)
            var page = openCard("energy", "MetricDetailPage")
            compare(page.title, "Energy burned")
            compare(byName(page, "metricToday").valueLabel.text, HealthText.number(Math.round(s.energyKcal)))
            compare(byName(page, "metricToday").unit, "Cal")
            compare(byName(page, "metricToday").captionLabel.text, "Today")
            compare(byName(page, "metricWeekChart").days.length, 7)
            colorIs(byName(page, "metricWeekChart").barColor, "#43DCD0")
            verify(byName(page, "metricAverage").valueLabel.text !== HealthText.none)
            back()
            page = openCard("distance", "MetricDetailPage")
            compare(page.title, "Distance")
            compare(byName(page, "metricToday").unit, HealthText.imperial ? "mi" : "km")
            compare(byName(page, "metricToday").valueLabel.text, (s.distanceM / (HealthText.imperial ? 1609.344 : 1000)).toLocaleString(Qt.locale(), "f", 2))
            shot("metric-distance")
            back()
            page = openCard("floors", "MetricDetailPage")
            compare(page.title, "Floors")
            // no floors climbed today: '- -'
            compare(byName(page, "metricToday").valueLabel.text, HealthText.none)
            back()
            page = openCard("azm", "MetricDetailPage")
            compare(page.title, "Active Zone Minutes")
            compare(byName(page, "metricToday").valueLabel.text, String(s.azm))
            compare(byName(page, "metricToday").noteLabel.text, HealthText.number(HealthData.azmWeek(HealthData.today)) + " of 150 this week")
            back()
            page = openCard("hourly", "MetricDetailPage")
            compare(page.title, "Hourly activity")
            compare(byName(page, "metricToday").valueLabel.text, String(s.hoursMet))
            compare(byName(page, "metricToday").unit, "hr")
            compare(byName(page, "metricToday").noteLabel.text, s.hoursMet >= 9 ? "Completed today" : s.hoursMet + " of 9 hr")
            var chart = byName(page, "metricDayChart")
            compare(chart.visible, true)
            compare(chart.goal, 250)
            compare(chart.bars.length, 24)
            // the week's goal line: the 9 hours that count
            compare(byName(page, "metricWeekChart").goal, 9)
            shot("metric-hourly")
            back()
        }

        function test_b_sleep() {
            use12h.value = true
            wait(300)
            var page = openCard("sleep", "SleepDetailPage")
            compare(page.title, "Sleep")
            noTimers(page, "sleep")
            var d = byName(page, "sleepDuration")
            compare(d.captionLabel.text, "Last night's sleep")
            compare(d.valueLabel.text, "7 hr")
            compare(d.noteLabel.text, "Good")
            colorIs(d.valueLabel.color, "#D8B9FF")
            var bed = byName(page, "sleepBedtime")
            var wake = byName(page, "sleepWake")
            compare(bed.captionLabel.text, "Bedtime")
            compare(wake.captionLabel.text, "Wake up")
            verify(/^11:10\s?pm$/i.test(bed.valueLabel.text), bed.valueLabel.text)
            verify(/^6:40\s?am$/i.test(wake.valueLabel.text), wake.valueLabel.text)
            compare(texts(byName(page, "stage0")).join("|").indexOf("Awake") >= 0, true)
            compare(byName(page, "stageValue0").text, "30 min · 7%")
            compare(byName(page, "stageValue1").text, "1 hr 30 min · 20%")
            compare(byName(page, "stageValue2").text, "4 hr · 53%")
            compare(byName(page, "stageValue3").text, "1 hr 30 min · 20%")
            use12h.value = false
            wait(400)
            verify(/^23:10$/.test(bed.valueLabel.text), bed.valueLabel.text)
            verify(/^0?6:40$/.test(wake.valueLabel.text), wake.valueLabel.text)
            use12h.value = true
            wait(300)
            shot("sleep-top")
            page.flickable.contentY = 250
            wait(300)
            shot("sleep-stages")
            checkTexts(page, "sleep-stages", true)
            back()
        }

        function confText() {
            var x = new XMLHttpRequest()
            x.open("GET", "file:///tmp/w3hlth/home/.config/asteroid/sensorlogd.conf", false)
            x.send()
            return x.responseText
        }

        // health-fitness-24: one list, changes at once, no Save button
        function test_c_settings() {
            devKey.value = false
            wait(300)
            var page = openCard("settings", "HealthSettingsPage")
            compare(page.title, "Settings")
            var all = texts(page)
            verify(all.indexOf("Daily step goal") >= 0)
            compare(all.indexOf("Enable steps goal"), -1)
            compare(all.indexOf("UI settings"), -1)
            compare(all.indexOf("Logger settings"), -1)
            compare(findAll(page, function(o) { return typeName(o) === "IconButton" }).length, 0)
            compare(byName(page, "goalRow").secondaryText, "8,000")
            compare(byName(page, "remindersRow").text, "Reminders to move")
            compare(byName(page, "remindersRow").checked, false)
            compare(byName(page, "highRow").text, "High heart rate")
            compare(byName(page, "highRow").checked, true)
            compare(byName(page, "lowRow").text, "Low heart rate")
            compare(byName(page, "lowRow").checked, true)
            compare(byName(page, "highRow").secondaryText, HealthData.metrics.defaultHighBpm() + " bpm")
            compare(byName(page, "lowRow").secondaryText, HealthData.metrics.defaultLowBpm() + " bpm")
            // stock has no logging row, with Developer options on or off
            compare(byName(page, "loggingRow"), null)
            shot("settings-top")
            // a switch applies at once: no Save, the daemon's file has it
            tapItem(page, byName(page, "remindersRow"))
            compare(HealthData.settings.remindersEnabled, true)
            verify(/\[reminders\][^\[]*enabled=true/.test(confText()), confText())
            tapItem(page, byName(page, "highRow"))
            compare(HealthData.settings.hrAlertHighEnabled, false)
            verify(/highEnabled=false/.test(confText()))
            tapItem(page, byName(page, "lowRow"))
            compare(HealthData.settings.hrAlertLowEnabled, false)
            // and back to stock's defaults
            for (var key in { remindersRow: 1, highRow: 1, lowRow: 1 })
                tapItem(page, byName(page, key))
            compare(HealthData.settings.remindersEnabled, false)
            compare(HealthData.settings.hrAlertHighEnabled, true)
            compare(HealthData.settings.hrAlertLowEnabled, true)
            // Developer options on: still no extra row (DECISIONS rule 2)
            devKey.value = true
            wait(400)
            compare(byName(page, "loggingRow"), null)
            compare(texts(page).indexOf("Logging"), -1)
            devKey.value = false
            back()
        }

        // the one goal: a full-screen stepper, 500 to 50,000, applied at once
        function test_d_stepGoal() {
            var page = openCard("settings", "HealthSettingsPage")
            tapItem(page, byName(page, "goalRow"))
            var goalPage = currentPage("StepGoalPage")
            var st = byName(goalPage, "goalStepper")
            compare(st.from, 500)
            compare(st.to, 50000)
            compare(st.stepSize, 500)
            compare(st.value, 8000)
            compare(byName(goalPage, "goalValue").text, "8,000")
            st.step(500)
            tryCompare(goalKey, "value", 8500)
            compare(HealthData.stepGoal, 8500)
            compare(byName(goalPage, "goalValue").text, "8,500")
            shot("step-goal")
            st.step(-500)
            tryCompare(goalKey, "value", 8000)
            back()
            // the list has the goal too
            compare(byName(page, "goalRow").secondaryText, "8,000")
            back()
            compare(todayPage().rows[0].subtitle, HealthText.number(8000 - HealthData.stepsOf(HealthData.today)) + " left")
        }

        // the launcher's tile and the Morning Brief notification open a page by the open key
        function test_e_openRequest() {
            openKey.value = "heartrate@" + Date.now()
            var hr = currentPage("HeartrateDetailPage")
            wait(300)
            compare(openKey.value, "")
            back()
            // an old request is ignored, so is a page that does not exist
            openKey.value = "heartrate@" + (Date.now() - 120000)
            wait(600)
            compare(stack().layers.length, 0)
            openKey.value = "nothing@" + Date.now()
            wait(600)
            compare(stack().layers.length, 0)
            // the Morning Brief: the greeting, the weather, last night, yesterday
            wId.value = 800
            wMax.value = 295
            wMin.value = 285
            fahrenheit.value = false
            wait(400)
            openKey.value = "morning@" + Date.now()
            var page = currentPage("MorningBriefPage")
            compare(page.title, "Morning Brief")
            compare(byName(page, "greeting").text, "Good morning! Here’s how your day is shaping up.")
            var weather = byName(page, "briefWeather")
            compare(weather.visible, true)
            compare(weather.value, "22° / 12°")
            compare(iconOf(weather).name, "ios-sunny-outline")
            compare(byName(page, "briefSleep").value, "7 hr")
            compare(byName(page, "briefSleep").subtitle, "Good")
            var y = HealthData.stepsOf(dayOf(1))
            compare(byName(page, "briefSteps").value, HealthText.number(y))
            compare(byName(page, "briefSteps").title, "Yesterday")
            compare(byName(page, "briefSteps").subtitle, HealthText.distanceText(HealthData.summary(dayOf(1)).distanceM))
            fahrenheit.value = true
            wait(400)
            compare(weather.value, "72° / 54°")
            shot("morning-top")
            page.flickable.contentY = 200
            wait(300)
            shot("morning-cards")
            checkTexts(page, "morning-cards", true)
            // a card of the brief opens that card's page
            var sleepCard = byName(page, "briefSleep")
            mouseClick(sleepCard, sleepCard.width / 2, 30)
            currentPage("SleepDetailPage")
            back()
            back()
            // without weather the weather card is left out
            wMax.value = 0
            wait(400)
            openKey.value = "morning@" + Date.now()
            page = currentPage("MorningBriefPage")
            compare(byName(page, "briefWeather").visible, false)
            back()
            fahrenheit.value = false
        }

        // the cards of the list come back from a settled stack: restart the app and compare
        function test_f_restart() {
            startApp()
            var page = todayPage()
            compare(page.rows.length, 11)
            noTimers(page, "today")
            // no sensor is on while the list is the page: the heart rate sensor is the heart rate page's
            compare(find(app, "HrmSensor"), null)
        }
    }
}
