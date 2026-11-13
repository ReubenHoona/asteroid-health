/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*
 * The numbers of the Relax app's breathing session (health-fitness-03), from stock's Relax (Fitbit CP3A):
 *   zzf.java:78-95   5000 ms of 'Inhale', then 5000 ms of 'Exhale': a breath is 10 s, 6 breaths a minute
 *   zza.java:8-46    easing: the inhale grows with cubic-bezier(0.40, 0, 0.25, 1), the exhale with (0.5, 0, 0.5, 1);
 *                    haptics: Inhale 50 steps of 40 ms (2.0 s), the amplitude falling 150 - 3 i (150 -> 3);
 *                    Exhale 50 steps of 40 ms rising 3 i (0 -> 147)
 *   zxp.java:158-163 the minutes picker 1-15, the second item (2 min) selected
 *   zxp.java:289-290 the picker items 68 x 82 dp, -8 dp between them
 *   res/raw 0x7f130000 (Relax_breath) two blobs of 24 % opacity in the primary-dim colour
 */

.pragma library

var PHASE_MS = 5000
var BREATH_MS = 10000
var BREATHS_PER_MINUTE = 6
var MIN_MINUTES = 1
var MAX_MINUTES = 15
var DEFAULT_MINUTES = 2
var BLOB_ALPHA = 0.24
// the haptic ramps: 50 steps of 40 ms
var HAPTIC_STEPS = 50
var HAPTIC_STEP_MS = 40
// the blobs' size as a share of the screen: the small and the large blob
var BLOB_SMALL = 0.45
var BLOB_LARGE = 0.8

// the easing curves: [x1, y1, x2, y2]
var INHALE_CURVE = [0.40, 0, 0.25, 1]
var EXHALE_CURVE = [0.5, 0, 0.5, 1]

function breaths(minutes) {
    return Math.max(1, Math.round(minutes)) * BREATHS_PER_MINUTE
}

function totalMs(minutes) {
    return breaths(minutes) * BREATH_MS
}

/* 'inhale' for the first 5 s of a breath, then 'exhale' */
function phaseAt(elapsedMs) {
    return (((elapsedMs % BREATH_MS) + BREATH_MS) % BREATH_MS) < PHASE_MS ? "inhale" : "exhale"
}

/* The y of a CSS cubic-bezier(x1, y1, x2, y2) at x (0..1), by bisection on the curve's parameter */
function bezier(curve, x) {
    if (x <= 0)
        return 0
    if (x >= 1)
        return 1
    var x1 = curve[0], y1 = curve[1], x2 = curve[2], y2 = curve[3]
    function bx(t) { return 3 * x1 * t * (1 - t) * (1 - t) + 3 * x2 * t * t * (1 - t) + t * t * t }
    function by(t) { return 3 * y1 * t * (1 - t) * (1 - t) + 3 * y2 * t * t * (1 - t) + t * t * t }
    var lo = 0
    var hi = 1
    for (var i = 0; i < 32; i++) {
        var m = (lo + hi) / 2
        if (bx(m) < x)
            lo = m
        else
            hi = m
    }
    return by((lo + hi) / 2)
}

/* The progress (0 small, 1 large) of the first blob at t (0..1) of a phase: it grows on the inhale and
 * shrinks on the exhale, the second blob is the other way round (1 - progress) */
function progress(phase, t) {
    if (phase === "inhale")
        return bezier(INHALE_CURVE, t)
    return 1 - bezier(EXHALE_CURVE, t)
}

/* The size of a blob (a share of the circle) for a progress */
function blobSize(p) {
    return BLOB_SMALL + (BLOB_LARGE - BLOB_SMALL) * p
}

/* The haptic ramps as [{ms, amp}] (amp 0..255, Android VibrationEffect.createWaveform) */
function inhaleWaveform() {
    var out = []
    for (var i = 0; i < HAPTIC_STEPS; i++)
        out.push({ ms: HAPTIC_STEP_MS, amp: 150 - i * 3 })
    return out
}

function exhaleWaveform() {
    var out = []
    for (var i = 0; i < HAPTIC_STEPS; i++)
        out.push({ ms: HAPTIC_STEP_MS, amp: i * 3 })
    return out
}

/* ngfd's haptic.waveform value ("40:150,40:147,...") for a ramp */
function waveformString(ramp) {
    return ramp.map(function(s) { return s.ms + ":" + s.amp }).join(",")
}

/* The moods stock offers after a session (strings 0x7f140aed-0x7f140af8), in stock's order */
var MOODS = ["calm", "content", "excited", "frustrated", "happy", "neutral", "pleasant", "sad", "stressed", "unpleasant", "worried"]
