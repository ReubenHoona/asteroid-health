// The tests' stand-in for the C++ RelaxLog (src/relax/relaxlog.cpp, tested on its own by tst_relaxlog):
// it only remembers what the app asked it to write.
import QtQuick

QtObject {
    property string directory: ""
    property var sessions: []
    property var moods: []
    function logSession(startMs, durationSeconds, hrStart, hrEnd) {
        sessions.push({ startMs: startMs, durationSeconds: durationSeconds, hrStart: hrStart, hrEnd: hrEnd })
        return true
    }
    function logMood(timeMs, mood) {
        moods.push({ timeMs: timeMs, mood: mood })
        return true
    }
}
