/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * The original launcher and metric icons (health-fitness-20) and the desktop entries of the two apps.
 */

import QtQuick
import QtTest

Item {
    width: 96
    height: 96

    Rectangle { id: holder; anchors.fill: parent; color: "black" }
    Image {
        id: img
        width: 96
        height: 96
        sourceSize: Qt.size(96, 96)
        asynchronous: false
        cache: false
    }

    TestCase {
        name: "HealthAssets"
        when: windowShown

        function read(rel) {
            var x = new XMLHttpRequest()
            x.open("GET", Qt.resolvedUrl(rel), false)
            x.send()
            return x.responseText
        }

        // the icons are drawn white, with ink in the middle 18 of 24 units, never filling the square
        function ink(name) {
            img.source = ""
            img.source = Qt.resolvedUrl("../icons/" + name + ".svg")
            tryCompare(img, "status", Image.Ready, 3000)
            wait(50)
            var shot = grabImage(holder.parent)
            shot.save("/tmp/w3hlth-shots/icon-" + name + ".png")
            var n = 0, minX = 96, maxX = 0, minY = 96, maxY = 0
            for (var y = 0; y < 96; y++)
                for (var x = 0; x < 96; x++)
                    if (shot.alpha(x, y) > 40 && shot.red(x, y) > 110) {
                        n++
                        minX = Math.min(minX, x)
                        maxX = Math.max(maxX, x)
                        minY = Math.min(minY, y)
                        maxY = Math.max(maxY, y)
                    }
            return { n: n, w: maxX - minX + 1, h: maxY - minY + 1, left: minX, right: maxX, top: minY, bottom: maxY }
        }

        function test_icons() {
            var names = ["eos-health", "eos-relax", "eos-health-steps", "eos-health-energy", "eos-health-distance",
                         "eos-health-floors", "eos-health-azm", "eos-health-hourly", "eos-health-heart",
                         "eos-health-resting", "eos-health-sleep", "eos-health-skintemp", "eos-health-skintemp-up",
                         "eos-health-skintemp-down"]
            for (var i = 0; i < names.length; i++) {
                var r = ink(names[i])
                verify(r.n > 200, names[i] + " has ink: " + r.n)
                verify(r.n < 96 * 96 * 0.6, names[i] + " is not a filled square: " + r.n)
                verify(r.w >= 40 && r.h >= 40, names[i] + " is a glyph of the icon size: " + r.w + "x" + r.h)
                verify(r.left >= 4 && r.top >= 4 && r.right <= 92 && r.bottom <= 92, names[i] + " stays inside the grid: " + JSON.stringify(r))
            }
        }

        function test_desktopEntries() {
            var health = read("../asteroid-health.desktop.template")
            var relax = read("../asteroid-relax.desktop.template")
            // the launcher draws a disc of the centre colour with the icon in white on it: FITNESS for Health,
            // WELLNESS for Relax (the mid tone of each palette), no Ionicons glyph and no teal gradient
            verify(/^Icon=eos-health$/m.test(health), health)
            verify(/^X-Asteroid-Center-Color=#00867D$/m.test(health))
            verify(/^X-Asteroid-Outer-Color=#00201E$/m.test(health))
            verify(/^Exec=asteroid-health$/m.test(health))
            verify(/^Icon=eos-relax$/m.test(relax), relax)
            verify(/^X-Asteroid-Center-Color=#8D62C5$/m.test(relax))
            verify(/^X-Asteroid-Outer-Color=#290055$/m.test(relax))
            verify(/^Exec=asteroid-relax$/m.test(relax))
            verify(health.indexOf("0097A6") < 0)
            var script = read("../asteroid-relax.in")
            verify(script.indexOf("asteroid-relax.so") > 0)
            // the launcher name of Relax
            verify(read("../i18n/asteroid-relax.desktop.h").indexOf("\"Relax\"") > 0)
            verify(read("../i18n/asteroid-relax.en.ts").indexOf("id-app-launcher-name") > 0)
        }
    }
}
