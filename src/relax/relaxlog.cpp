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

#include "relaxlog.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>

RelaxLog::RelaxLog(QObject *parent) : QObject(parent)
{
    // where sensorlogd keeps its files (common.cpp sensorDirPath)
    QSettings settings("asteroid", "sensorlogd");
    m_directory = settings.value("loggerRootPath",
                                 QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.asteroid-sensorlogd/").toString();
    if (!m_directory.endsWith('/'))
        m_directory += '/';
}

QString RelaxLog::directory() const
{
    return m_directory;
}

void RelaxLog::setDirectory(const QString &directory)
{
    QString d = directory;
    if (!d.isEmpty() && !d.endsWith('/'))
        d += '/';
    if (d == m_directory)
        return;
    m_directory = d;
    emit directoryChanged();
}

QString RelaxLog::sessionLine(qint64 startMs, int durationSeconds, int hrStart, int hrEnd)
{
    return QString::number(startMs / 1000) + ':' + QString::number(qMax(0, durationSeconds)) + ':'
            + QString::number(qMax(0, hrStart)) + ':' + QString::number(qMax(0, hrEnd));
}

QString RelaxLog::moodLine(qint64 timeMs, const QString &mood)
{
    // a mood is one word of a fixed list: nothing that could break the line
    QString clean = mood;
    clean.remove(QRegularExpression("[^A-Za-z]"));
    return QString::number(timeMs / 1000) + ':' + clean.toLower();
}

QString RelaxLog::fileFor(const char *kind, qint64 ms) const
{
    return m_directory + kind + '/' + QDateTime::fromMSecsSinceEpoch(ms).date().toString("yyyy-MM-dd") + ".log";
}

bool RelaxLog::appendLine(const QString &path, const QString &line)
{
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::Append | QIODevice::Text))
        return false;
    QTextStream out(&file);
    out << line << '\n';
    out.flush();
    return file.error() == QFileDevice::NoError;
}

bool RelaxLog::logSession(double startMs, int durationSeconds, int hrStart, int hrEnd)
{
    const qint64 start = (qint64)startMs;
    return appendLine(fileFor("relax", start), sessionLine(start, durationSeconds, hrStart, hrEnd));
}

bool RelaxLog::logMood(double timeMs, const QString &mood)
{
    const qint64 time = (qint64)timeMs;
    return appendLine(fileFor("mood", time), moodLine(time, mood));
}

QStringList RelaxLog::readLines(const char *kind, const QDate &day) const
{
    QStringList lines;
    QFile file(m_directory + kind + '/' + day.toString("yyyy-MM-dd") + ".log");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return lines;
    QTextStream in(&file);
    while (!in.atEnd()) {
        const QString line = in.readLine();
        if (!line.isEmpty())
            lines << line;
    }
    return lines;
}

QStringList RelaxLog::sessionLines(const QDate &day) const
{
    return readLines("relax", day);
}

QStringList RelaxLog::moodLines(const QDate &day) const
{
    return readLines("mood", day);
}
