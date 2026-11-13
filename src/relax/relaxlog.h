/*
 * Copyright (C) 2026 eos-mainline contributors
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

#ifndef RELAXLOG_H
#define RELAXLOG_H

#include <QDate>
#include <QObject>
#include <QString>

/*
 * The Relax sessions in sensorlogd's data directory (health-fitness-03: "log sessions to sensorlogd"), in the
 * format of its day files (one line per record, "seconds since the epoch:value"), a file per local day:
 *
 *   relax/<yyyy-MM-dd>.log   <start>:<duration in seconds>:<heart rate at the start>:<heart rate at the end>
 *   mood/<yyyy-MM-dd>.log    <time>:<mood>
 *
 * (a heart rate of 0: none was measured). The directory is the logger's own: ~/.asteroid-sensorlogd/, or the
 * "loggerRootPath" of its settings. Plain data, never read by anything outside the device. Nothing runs here
 * until a line is written (a session's end, a mood).
 */
class RelaxLog : public QObject
{
    Q_OBJECT
    // the sensorlogd data directory (with the closing slash); default as the logger's
    Q_PROPERTY(QString directory READ directory WRITE setDirectory NOTIFY directoryChanged)

public:
    explicit RelaxLog(QObject *parent = nullptr);

    QString directory() const;
    void setDirectory(const QString &directory);

    // a finished session: false if the file could not be written
    Q_INVOKABLE bool logSession(double startMs, int durationSeconds, int hrStart, int hrEnd);
    // a mood chosen after a session
    Q_INVOKABLE bool logMood(double timeMs, const QString &mood);

    // the lines of the day files, as written (tests, a future history page)
    Q_INVOKABLE QStringList sessionLines(const QDate &day) const;
    Q_INVOKABLE QStringList moodLines(const QDate &day) const;

    // the line of a record
    static QString sessionLine(qint64 startMs, int durationSeconds, int hrStart, int hrEnd);
    static QString moodLine(qint64 timeMs, const QString &mood);

signals:
    void directoryChanged();

private:
    QString fileFor(const char *kind, qint64 ms) const;
    static bool appendLine(const QString &path, const QString &line);
    QStringList readLines(const char *kind, const QDate &day) const;

    QString m_directory;
};

#endif // RELAXLOG_H
