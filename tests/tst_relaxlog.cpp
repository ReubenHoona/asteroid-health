/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * RelaxLog (src/relax/relaxlog.cpp): the files of the Relax sessions in sensorlogd's data directory.
 */

#include <QtTest>

#include "../src/relax/relaxlog.h"

class TestRelaxLog : public QObject
{
    Q_OBJECT
private slots:
    void lines()
    {
        QCOMPARE(RelaxLog::sessionLine(1731540000123, 120, 68, 62), QString("1731540000:120:68:62"));
        // no heart rate: 0; a negative duration is none
        QCOMPARE(RelaxLog::sessionLine(1731540000999, 60, 0, 0), QString("1731540000:60:0:0"));
        QCOMPARE(RelaxLog::sessionLine(1000, -5, -1, 70), QString("1:0:0:70"));
        QCOMPARE(RelaxLog::moodLine(1731540100500, "Happy"), QString("1731540100:happy"));
        // nothing that could break the line
        QCOMPARE(RelaxLog::moodLine(5000, "sad\n9:9"), QString("5:sad"));
    }

    void writesTheDayFiles()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        RelaxLog log;
        log.setDirectory(dir.path());
        QCOMPARE(log.directory(), dir.path() + "/");
        const QDateTime start = QDateTime(QDate(2026, 11, 13), QTime(9, 30, 0));
        QVERIFY(log.logSession(start.toMSecsSinceEpoch(), 120, 70, 61));
        QVERIFY(log.logSession(start.addSecs(3600).toMSecsSinceEpoch(), 60, 0, 0));
        QVERIFY(log.logMood(start.addSecs(130).toMSecsSinceEpoch(), "calm"));
        // a session the next day goes to the next day's file
        QVERIFY(log.logSession(start.addDays(1).toMSecsSinceEpoch(), 360, 66, 60));
        QVERIFY(QFile::exists(dir.path() + "/relax/2026-11-13.log"));
        QVERIFY(QFile::exists(dir.path() + "/relax/2026-11-14.log"));
        QVERIFY(QFile::exists(dir.path() + "/mood/2026-11-13.log"));
        const QStringList day = log.sessionLines(QDate(2026, 11, 13));
        QCOMPARE(day.size(), 2);
        QCOMPARE(day[0], QString::number(start.toSecsSinceEpoch()) + ":120:70:61");
        QCOMPARE(day[1], QString::number(start.addSecs(3600).toSecsSinceEpoch()) + ":60:0:0");
        QCOMPARE(log.sessionLines(QDate(2026, 11, 14)).size(), 1);
        QCOMPARE(log.sessionLines(QDate(2026, 11, 15)).size(), 0);
        QCOMPARE(log.moodLines(QDate(2026, 11, 13)), QStringList{QString::number(start.addSecs(130).toSecsSinceEpoch()) + ":calm"});
        // the format of the logger's day files: seconds, then values after a colon, one record a line
        for (const QString &line : day) {
            const QStringList parts = line.split(':');
            QCOMPARE(parts.size(), 4);
            bool ok = false;
            QVERIFY(parts[0].toLongLong(&ok) > 1000000000 && ok);
        }
    }

    void defaultDirectoryIsTheLoggers()
    {
        // ~/.asteroid-sensorlogd/ (or the "loggerRootPath" of the logger's settings), with the closing slash
        RelaxLog log;
        QVERIFY(log.directory().endsWith("/"));
        QVERIFY(log.directory().contains(".asteroid-sensorlogd") || !QSettings("asteroid", "sensorlogd").value("loggerRootPath").toString().isEmpty());
    }

    void unwritableDirectoryFails()
    {
        RelaxLog log;
        log.setDirectory("/proc/nonexistent-relax-dir");
        QVERIFY(!log.logSession(1731540000000.0, 60, 0, 0));
        QVERIFY(!log.logMood(1731540000000.0, "sad"));
    }

    void directorySignal()
    {
        RelaxLog log;
        QSignalSpy spy(&log, &RelaxLog::directoryChanged);
        log.setDirectory("/tmp/relax-a");
        QCOMPARE(spy.count(), 1);
        log.setDirectory("/tmp/relax-a/");
        QCOMPARE(spy.count(), 1);
    }
};

QTEST_MAIN(TestRelaxLog)
#include "tst_relaxlog.moc"
