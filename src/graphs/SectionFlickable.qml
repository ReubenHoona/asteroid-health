/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
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

// A page of screen-high sections (the visible children of `sections`, a
// Column in this Flickable) that always comes to rest on one of them, as
// Wear OS's VerticalPager: a fling (at least 400 dp/s, as the pager's) goes
// one section on, anything slower to the nearest section (at most one away)
// when let go, and either settles in 250 ms. The crown scrolls the page freely (org.asteroid.controls'
// RotaryInput); when it stops, the page settles on the next section once
// it has turned past a sixth of one (about 2 ticks, as the pager's high
// rotary snap sensitivity), else back.
Flickable {
    id: flick
    property Item sections: null
    // the section the page rests on, or is settling on
    property int current: 0
    property Item currentItem: null
    // how far the crown turns before it moves on a section
    property real crownThreshold: height / 6
    // the slowest fling that goes on a section: 400 dp/s (the Pixel Watch 2
    // screen is 192 dp wide)
    property real minFlingVelocity: width * 400 / 192
    property real snapY: 0

    property int _gestureStart: 0
    property bool _setting: false
    property bool _crown: false
    property int _crownStart: 0

    flickableDirection: Flickable.VerticalFlick

    function _visible() {
        var out = []
        var kids = sections ? sections.children : []
        for (var i = 0; i < kids.length; i++)
            if (kids[i].visible && kids[i].height > 0)
                out.push(kids[i])
        return out
    }

    // where each visible section starts (from their heights: the Column may
    // not have laid them out yet), the last ones held to the end of the page
    function stops() {
        var items = _visible()
        var total = 0
        var ys = []
        for (var i = 0; i < items.length; i++) {
            ys.push(total)
            total += items[i].height
        }
        var end = Math.max(0, total - height)
        for (var j = 0; j < ys.length; j++)
            ys[j] = Math.min(ys[j], end)
        return ys.length ? ys : [0]
    }

    function nearestIndex(y) {
        var ys = stops()
        var best = 0
        for (var i = 1; i < ys.length; i++)
            if (Math.abs(ys[i] - y) < Math.abs(ys[best] - y))
                best = i
        return best
    }

    function _set(y) {
        _setting = true
        contentY = y
        _setting = false
    }

    function snapTo(i, animated) {
        var ys = stops()
        i = Math.max(0, Math.min(ys.length - 1, i))
        current = i
        currentItem = _visible()[i] || null
        snapAnim.stop()
        if (!animated || Math.abs(contentY - ys[i]) < 1) {
            _set(ys[i])
            return
        }
        snapY = contentY
        snapAnim.to = ys[i]
        snapAnim.start()
    }

    // sections shown or hidden (a day with or without data): stay on the
    // same one, or the one before it if it went
    function relayout() {
        if (dragging || flicking)
            return
        var items = _visible()
        var i = items.indexOf(currentItem)
        if (i < 0 && currentItem && sections) {
            var kids = sections.children
            var at = -1
            for (var j = 0; j < kids.length; j++)
                if (kids[j] === currentItem)
                    at = j
            for (var k = at - 1; k >= 0 && i < 0; k--)
                i = items.indexOf(kids[k])
        }
        snapTo(Math.max(0, i), false)
    }

    onSnapYChanged: if (snapAnim.running) _set(snapY)
    NumberAnimation {
        id: snapAnim
        target: flick
        property: "snapY"
        duration: 250
        easing.type: Easing.OutCubic
        onFinished: flick._set(to)
    }

    onDraggingChanged: {
        if (dragging) {
            snapAnim.stop()
            crownTimer.stop()
            _crown = false
            _gestureStart = nearestIndex(contentY)
        }
    }
    function _settleDrag() {
        snapTo(Math.max(_gestureStart - 1, Math.min(_gestureStart + 1, nearestIndex(contentY))), true)
    }
    onFlickStarted: {
        var v = verticalVelocity
        if (Math.abs(v) >= minFlingVelocity)
            snapTo(_gestureStart + (v > 0 ? 1 : -1), true)
        else
            _settleDrag()
        cancelFlick()
    }
    onMovementEnded: {
        if (!snapAnim.running)
            _settleDrag()
    }

    // the page moved by neither a finger nor the settling: the crown
    onContentYChanged: {
        if (_setting || moving || dragging)
            return
        snapAnim.stop()
        if (!_crown) {
            _crown = true
            _crownStart = current
        }
        crownTimer.restart()
    }
    Timer {
        id: crownTimer
        interval: 150
        onTriggered: {
            flick._crown = false
            var ys = flick.stops()
            var start = Math.min(flick._crownStart, ys.length - 1)
            var moved = flick.contentY - ys[start]
            var i = flick.nearestIndex(flick.contentY)
            if (i === start && Math.abs(moved) >= flick.crownThreshold)
                i = start + (moved > 0 ? 1 : -1)
            flick.snapTo(i, true)
        }
    }

    onContentHeightChanged: Qt.callLater(relayout)
    onHeightChanged: Qt.callLater(relayout)
}
