/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Relax (health-fitness-03) on a 384x384 round screen: the numbers of stock's breathing session (zza.java,
 * zzf.java, zxp.java: 5 s phases, easing curves, the haptic ramps, the picker), the start page, the first-run
 * text, the settings, a session (fast clock, and one in real time for the first phase), the recap and the mood.
 */

import QtQuick
import QtTest
import Nemo.Configuration
import org.asteroid.controls

import "../src/relax"
import "../src/relax/Breath.js" as Breath

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
            }
        }
    }

    ConfigurationValue { id: introKey; key: "/org/asteroidos/health/relax/intro-seen"; defaultValue: false }
    ConfigurationValue { id: vibKey; key: "/org/asteroidos/health/relax/vibrations"; defaultValue: true }

    TestCase {
        name: "Relax"
        when: windowShown

        property string shots: "/tmp/w3hlth-shots"
        property var app: null
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

        function texts(item) {
            return findAll(item, function(o) {
                return o.text !== undefined && typeof o.text === "string" && o.text !== "" && o.contentWidth !== undefined
            }).map(function(o) { return o.text })
        }

        function shot(name) {
            wait(250)
            grabImage(screen).save(shots + "/" + name + ".png")
        }

        function init() {
            problems = []
        }

        function startApp(scale) {
            if (app)
                app.destroy()
            wait(50)
            var c = Qt.createComponent(Qt.resolvedUrl("../src/relax_main.qml"))
            compare(c.status, Component.Ready, c.errorString())
            app = c.createObject(host, { width: 384, height: 384 })
            verify(app)
            if (scale)
                app.timeScale = scale
            wait(700)
        }

        function stack() {
            return byName(app, "relaxStack")
        }

        function page() {
            var s = stack()
            return s.currentLayer ? s.currentLayer : s.firstPageItem
        }

        function tap(item) {
            mouseClick(item, item.width / 2, item.height / 2)
            wait(700)
        }

        // the numbers of stock
        function test_0_numbers() {
            compare(Breath.PHASE_MS, 5000)
            compare(Breath.BREATH_MS, 10000)
            compare(Breath.BREATHS_PER_MINUTE, 6)
            compare(Breath.breaths(1), 6)
            compare(Breath.breaths(2), 12)
            compare(Breath.breaths(15), 90)
            compare(Breath.totalMs(2), 120000)
            compare(Breath.MIN_MINUTES, 1)
            compare(Breath.MAX_MINUTES, 15)
            compare(Breath.DEFAULT_MINUTES, 2)
            compare(Breath.BLOB_ALPHA, 0.24)
            compare(Breath.phaseAt(0), "inhale")
            compare(Breath.phaseAt(4999), "inhale")
            compare(Breath.phaseAt(5000), "exhale")
            compare(Breath.phaseAt(9999), "exhale")
            compare(Breath.phaseAt(10000), "inhale")
            // cubic-bezier(0.40, 0, 0.25, 1) for the inhale, (0.5, 0, 0.5, 1) for the exhale
            compare(Breath.INHALE_CURVE.join(","), "0.4,0,0.25,1")
            compare(Breath.EXHALE_CURVE.join(","), "0.5,0,0.5,1")
            var inh = [[0.1, 0.0252], [0.25, 0.2146], [0.5, 0.746], [0.75, 0.9537], [0.9, 0.9936]]
            for (var i = 0; i < inh.length; i++)
                verify(Math.abs(Breath.bezier(Breath.INHALE_CURVE, inh[i][0]) - inh[i][1]) < 1e-3, "inhale " + inh[i][0])
            var exh = [[0.1, 0.0146], [0.25, 0.1059], [0.5, 0.5], [0.75, 0.8941], [0.9, 0.9854]]
            for (var j = 0; j < exh.length; j++)
                verify(Math.abs(Breath.bezier(Breath.EXHALE_CURVE, exh[j][0]) - exh[j][1]) < 1e-3, "exhale " + exh[j][0])
            compare(Breath.bezier(Breath.INHALE_CURVE, 0), 0)
            compare(Breath.bezier(Breath.INHALE_CURVE, 1), 1)
            // the blob: grows on the inhale, shrinks on the exhale, the other blob the other way round
            compare(Breath.progress("inhale", 0), 0)
            compare(Breath.progress("inhale", 1), 1)
            compare(Breath.progress("exhale", 0), 1)
            compare(Breath.progress("exhale", 1), 0)
            verify(Breath.blobSize(0) < Breath.blobSize(1))
            // the haptic ramps: 50 steps of 40 ms (2.0 s); inhale 150 -> 3, exhale 0 -> 147
            var a = Breath.inhaleWaveform()
            var b = Breath.exhaleWaveform()
            compare(a.length, 50)
            compare(b.length, 50)
            compare(a[0].amp, 150)
            compare(a[49].amp, 3)
            compare(b[0].amp, 0)
            compare(b[49].amp, 147)
            compare(a.reduce(function(s, x) { return s + x.ms }, 0), 2000)
            verify(a.every(function(x, k) { return x.ms === 40 && x.amp === 150 - 3 * k }))
            verify(b.every(function(x, k) { return x.ms === 40 && x.amp === 3 * k }))
            compare(Breath.waveformString(a).split(",").length, 50)
            compare(Breath.waveformString(a).substring(0, 22), "40:150,40:147,40:144,4")
            // eleven moods in stock's order
            compare(Breath.MOODS.join(" "), "calm content excited frustrated happy neutral pleasant sad stressed unpleasant worried")
        }

        // the first run: the intro, once
        function test_1_intro() {
            introKey.value = false
            wait(300)
            startApp()
            var intro = page()
            compare(typeName(intro), "RelaxIntroPage")
            compare(byName(intro, "introTitle").text, "Ready to relax?")
            compare(byName(intro, "introText").text, "Calm your body and mind with a guided breathing session")
            shot("relax-intro")
            tap(byName(intro, "introStart"))
            tryCompare(introKey, "value", true)
            compare(stack().layers.length, 0)
            // the second time there is no intro
            startApp()
            compare(stack().layers.length, 0)
            compare(byName(app, "breatheTitle").text, "Breathe")
        }

        function test_2_startPage() {
            introKey.value = true
            wait(300)
            startApp()
            var p = page()
            var title = byName(p, "breatheTitle")
            compare(title.text, "Breathe")
            // 16 dp (32 px) from the top, plus the scaffold margin
            verify(title.mapToItem(p, 0, 0).y >= Theme.dp(16) - 1 && title.mapToItem(p, 0, 0).y < Theme.dp(16) + 60, "title y " + title.mapToItem(p, 0, 0).y)
            var picker = byName(p, "minutesPicker")
            compare(picker.count, 15)
            compare(picker.selectedOption, 1)
            compare(picker.minutes, 2)
            compare(picker.repeatItems, false)
            compare(picker.optionHeight, Theme.dp(82))
            compare(picker.optionSpacing, -Theme.dp(8))
            compare(picker.width, Theme.dp(68))
            compare(picker.role, "numeralMedium")
            compare(picker.textFor(0), "1")
            compare(picker.textFor(14), "15")
            compare(byName(p, "minLabel").text, "min")
            verify(byName(p, "minLabel").mapToItem(p, 0, 0).x > picker.mapToItem(p, 0, 0).x + picker.width - 1)
            // read out as stock does
            var box = picker.parent
            compare(box.Accessible.name, "2 minutes")
            compare(box.Accessible.description, "Use 2-finger swipe, or turn crown or bezel to change")
            compare(byName(p, "startButton").text, "Start")
            compare(byName(p, "startButton").iconName, "ios-arrow-forward")
            compare(byName(p, "settingsButton").iconName, "ios-settings-outline")
            // nothing runs on the start page
            compare(findAll(app, function(o) { return o.running === true && o.interval !== undefined }).length, 0)
            shot("relax-start")
            // a picked number is what Start asks for
            picker.selectedOption = 4
            compare(picker.minutes, 5)
            compare(box.Accessible.name, "5 minutes")
            picker.selectedOption = 1
        }

        function test_3_settings() {
            vibKey.value = true
            wait(300)
            startApp()
            tap(byName(page(), "settingsButton"))
            var s = page()
            compare(typeName(s), "RelaxSettingsPage")
            compare(s.title, "Session settings")
            var row = byName(s, "vibrationsRow")
            compare(row.text, "Vibrations")
            compare(row.checked, true)
            shot("relax-settings")
            tap(row)
            tryCompare(vibKey, "value", false)
            compare(row.checked, false)
            tap(row)
            tryCompare(vibKey, "value", true)
            // the back swipe is the way out
            mouseDrag(screen, 100, 250, 180, 0, Qt.LeftButton, Qt.NoModifier, 30)
            wait(900)
            compare(stack().layers.length, 0)
        }

        // a whole session on a clock 20 times faster (a breath in half a second): the phases, the haptics, the recap, the mood, the log
        function test_4_session() {
            vibKey.value = true
            wait(300)
            startApp(20)
            var picker = byName(page(), "minutesPicker")
            picker.selectedOption = 0
            tap(byName(page(), "startButton"))
            var s = find(app, "BreathSession")
            verify(s)
            compare(s.totalBreaths, 6)
            compare(s.minutes, 1)
            // set the heart rates the sensor would have given
            s.hrStart = 71
            s.hrEnd = 64
            tryCompare(s, "running", false, 8000)
            compare(s.breathsDone, 6)
            var want = []
            for (var i = 0; i < 6; i++)
                want.push("inhale", "exhale")
            compare(s.phases.join(" "), want.join(" "))
            // the ramp vibrations of each phase through ngfd
            var wantEvents = []
            for (var j = 0; j < 6; j++)
                wantEvents.push("relax_inhale", "relax_exhale")
            compare(s.played.join(" "), wantEvents.join(" "))
            wait(700)
            // the recap over the session
            var recap = page()
            compare(typeName(recap), "RelaxRecapPage")
            compare(recap.title, "Session complete")
            compare(byName(recap, "relaxIcon").width, Theme.dp(48))
            compare(byName(recap, "relaxIcon").name, "eos-relax")
            verify(texts(recap).indexOf("Relax recap") >= 0)
            compare(byName(recap, "hrStart").valueLabel.text, "71")
            compare(byName(recap, "hrEnd").valueLabel.text, "64")
            compare(byName(recap, "hrStart").unit, "bpm")
            // the session is in the log: 60 s, the heart rates
            compare(app.log.sessions.length, 1)
            compare(app.log.sessions[0].durationSeconds, 60)
            compare(app.log.sessions[0].hrStart, 71)
            compare(app.log.sessions[0].hrEnd, 64)
            verify(Math.abs(app.log.sessions[0].startMs - Date.now()) < 10000)
            // the burst: 2.0 s, then the loop
            var burst = byName(recap, "burst")
            tryCompare(burst, "spread", 1, 3000)
            compare(burst.burstMs, 2000)
            compare(burst.loopMs, 5020)
            compare(burst.animating, true)
            shot("relax-recap")
            // the display is held only while a session runs
            compare(byName(app, "keepAwake").held, false)
            // Log mood: the eleven moods
            var moodButton = byName(recap, "moodButton")
            compare(moodButton.text, "Log mood")
            recap.flickable.contentY = Math.max(0, moodButton.mapToItem(recap.flickable.contentItem, 0, 0).y - 150)
            wait(300)
            tap(moodButton)
            var moods = page()
            compare(typeName(moods), "RelaxMoodPage")
            compare(moods.title, "Log mood")
            var labels = findAll(moods, function(o) { return typeof o.objectName === "string" && o.objectName.indexOf("mood-") === 0 }).map(function(o) { return o.text })
            compare(labels.join(" "), "Calm Content Excited Frustrated Happy Neutral Pleasant Sad Stressed Unpleasant Worried")
            shot("relax-mood")
            var happy = byName(moods, "mood-happy")
            moods.flickable.contentY = Math.max(0, happy.mapToItem(moods.flickable.contentItem, 0, 0).y - 150)
            wait(300)
            tap(happy)
            recap = page()
            compare(typeName(recap), "RelaxRecapPage")
            compare(byName(recap, "moodButton").text, "Mood logged")
            compare(byName(recap, "moodButton").enabled, false)
            compare(app.log.moods.length, 1)
            compare(app.log.moods[0].mood, "happy")
            // Done: back at the start page
            var done = byName(recap, "doneButton")
            recap.flickable.contentY = Math.max(0, done.mapToItem(recap.flickable.contentItem, 0, 0).y - 150)
            wait(300)
            tap(done)
            wait(500)
            compare(stack().layers.length, 0)
            compare(byName(app, "breatheTitle").text, "Breathe")
        }

        // with Vibrations off the session is silent
        function test_5_noVibrations() {
            vibKey.value = false
            wait(400)
            startApp(100)
            byName(page(), "minutesPicker").selectedOption = 0
            tap(byName(page(), "startButton"))
            var s = find(app, "BreathSession")
            compare(s.vibrations, false)
            tryCompare(s, "running", false, 4000)
            compare(s.phases.length, 12)
            compare(s.played.length, 0)
            vibKey.value = true
        }

        // real time: the first phase of a session, 5 s of inhale, then the exhale
        function test_6_realTime() {
            vibKey.value = true
            wait(300)
            startApp()
            byName(page(), "minutesPicker").selectedOption = 0
            tap(byName(page(), "startButton"))
            var s = find(app, "BreathSession")
            var started = s.startedAt
            compare(s.timeScale, 1)
            compare(s.running, true)
            compare(byName(app, "keepAwake").active, true)
            compare(s.phase, "inhale")
            compare(byName(s, "phaseText").text, "Inhale")
            // the two blobs: 24 % of the primary-dim colour
            var a = byName(s, "blobA")
            var b = byName(s, "blobB")
            var dim = Theme.color.primaryDim
            verify(Math.abs(a.color.a - 0.24) < 0.005 && Math.abs(a.color.r - dim.r) < 0.005 && Math.abs(a.color.g - dim.g) < 0.005 && Math.abs(a.color.b - dim.b) < 0.005)
            verify(Math.abs(b.color.a - 0.24) < 0.005)
            // one grows while the other shrinks: A small, B large at the start
            verify(a.width < b.width, "start sizes " + a.width + " " + b.width)
            wait(2200)
            var elapsed = (Date.now() - started) / 1000
            // the inhale's curve: p at 2.5 s is bezier(0.5) = 0.746
            wait(Math.max(0, 2500 - (Date.now() - started)))
            var pAt = s.p
            var t = (Date.now() - started) / 5000
            verify(Math.abs(pAt - Breath.progress("inhale", t)) < 0.1, "p " + pAt + " at " + t)
            verify(a.width > Theme.dp(1) && Math.abs(a.width - 384 * Breath.blobSize(s.p)) < 40)
            shot("relax-inhale")
            // the phase changes at 5 s
            tryCompare(s, "phase", "exhale", 4000)
            var at = Date.now() - started
            verify(at > 4700 && at < 6200, "exhale began at " + at)
            compare(byName(s, "phaseText").text, "Exhale")
            wait(1500)
            shot("relax-exhale")
            // back out of the session: the keep-awake lets go
            mouseDrag(screen, 100, 250, 180, 0, Qt.LeftButton, Qt.NoModifier, 30)
            wait(1200)
            compare(stack().layers.length, 0)
            compare(find(app, "BreathSession"), null)
            compare(find(app, "HrmSensor"), null)
        }
    }
}
