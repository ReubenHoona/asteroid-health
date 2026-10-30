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
import org.asteroid.controls

// A sideways swipe across a day: to the right the day before (as a pager
// whose older pages are on the left), to the left the day after. Vertical
// drags stay the page's scrolling. A swipe from the left edge still goes
// back, as Wear OS's edgeSwipeToDismiss (24 dp) on horizontally swiped
// content. What the area holds is drawn over it and gets taps first.
Item {
    id: area
    signal previous()
    signal next()

    MouseArea {
        z: -1
        x: Dims.w(12.5)
        width: parent.width - x
        height: parent.height
        // the swipe is the day's, not the page's back swipe (BackSwipeArea)
        property bool blocksBackSwipe: true
        property real pressX
        property real pressY

        onPressed: (mouse) => { pressX = mouse.x; pressY = mouse.y }
        onReleased: (mouse) => {
            var dx = mouse.x - pressX
            if (Math.abs(dx) > Dims.w(12) && Math.abs(dx) > 2 * Math.abs(mouse.y - pressY)) {
                if (dx > 0)
                    area.previous()
                else
                    area.next()
            }
        }
    }
}
