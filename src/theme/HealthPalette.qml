/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma Singleton

import QtQuick

/*
 * The colours of the Health screens of stock (Google Health / Fitbit on Wear OS, CP3A):
 * black pages and three category palettes of five tones each, and the greys of the charts.
 *
 *   FITNESS   steps, main goal, energy, distance, floors, Active Zone Minutes, hourly activity
 *   HEALTH    heart rate, resting heart rate
 *   WELLNESS  sleep, relax
 *
 * Stock: ColorPaletteCompat.java:44-58 (the 5 tones), vrh.java:48-92 and vrg.java:49-160 (which
 * category each metric uses), flex_lite_tile_{heartrate,primarygoal,sleep}_preview.xml (the tile
 * accents), health-fitness-20. The tones are [main, mid, dark, deep, light].
 */
QtObject {
    // the 5 tones of a category: main (icons, values, chart bars), mid, dark, deep, light
    readonly property var fitness: ({ main: "#43DCD0", mid: "#00867D", dark: "#00504B", deep: "#00201E", light: "#90F4EA" })
    readonly property var health: ({ main: "#2BC7F7", mid: "#0081A8", dark: "#004D68", deep: "#001F2D", light: "#BDE9FF" })
    readonly property var wellness: ({ main: "#D8B9FF", mid: "#8D62C5", dark: "#5A2F90", deep: "#290055", light: "#EDDCFF" })

    // the accent of the tiles (and complications) of the same metrics
    readonly property color tileFitness: "#80F7DD"
    readonly property color tileHealth: "#94D6FF"
    readonly property color tileWellness: "#E5C7FF"

    // chart track (the empty part of a ring or bar), chart labels, body text on black
    readonly property color track: "#2D3130"
    readonly property color label: "#BEC8C6"
    readonly property color text: "#DADCE0"

    // the palette of a category by name ("fitness", "health", "wellness")
    function category(name) {
        return name === "health" ? health : name === "wellness" ? wellness : fitness
    }
}
