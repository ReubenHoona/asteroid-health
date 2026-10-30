// Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// The host tests' stand-in for the app's C++ LineGraph_p (main.cpp registers
// it; the weight graph still uses it): draws nothing
import QtQuick

Item {
    property real lineWidth: 0
    property color lineColor: "white"
    property int maxValue: 0
    property int minValue: 0
    property date maxTime: new Date()
    property date minTime: new Date()
    property bool relativeMode: false
    signal loadingDone()
    function loadGraphData(data) { loadingDone() }
}
