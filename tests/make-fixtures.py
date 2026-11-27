#!/usr/bin/env python3
# Copyright (C) 2026 eos
# SPDX-License-Identifier: GPL-3.0-or-later
#
# make-fixtures.py HOME: fictional sensorlogd day files under
# HOME/.asteroid-sensorlogd for the host tests, in the local time zone of
# the run (TZ), dated relative to today:
#   today      heart rate every 10 minutes up to 5 minutes ago, a workout
#              in the morning (every minute), not worn for an hour, and
#              lines no reader may count (garbage, off the wrist, out of
#              range, one from the day before); steps
#   today-1    a full day; 8 2xx steps
#   today-2    nothing (not worn)
#   today-3    heart rate 10:00-18:00 with malformed lines in the file
#   today-4    a single heart rate reading; a single step record
#   today-5    a full day, the step goal reached
#   today-6    a full day
# a second argument: "empty" writes no data, "stale" ends today's readings three hours ago
# plus heartrate.db (every valid reading of the day files, for the zones and Active Zone Minutes),
# health.db's daily rows with the resting heart rate sensorlogd estimates once a day (today 52,
# today-1 54, today-3 55, today-5 53, today-6 51),
# last night's sleep (sleep/<today>.json: 450 minutes in bed, 420 asleep: 90 REM, 240 light, 90 deep) and
# 2026-01-15 (tst_data.qml: the malformed lines the loaders skip) and
# the step goal (8000) in HOME/.config/asteroid/sensorlogd.conf.
import json
import math
import os
import sqlite3
import random
import sys
import time
from datetime import date, datetime, timedelta

home = sys.argv[1]
# mode "": the days below; "empty": no data at all (a new watch); "stale": today's last reading three hours ago
mode = sys.argv[2] if len(sys.argv) > 2 else ""
root = os.path.join(home, ".asteroid-sensorlogd")
hr_dir = os.path.join(root, "heartrateMonitor")
st_dir = os.path.join(root, "stepCounter")
for d in (hr_dir, st_dir, os.path.join(home, ".config", "asteroid")):
    os.makedirs(d, exist_ok=True)
for d in (hr_dir, st_dir):
    for f in os.listdir(d):
        os.unlink(os.path.join(d, f))

rnd = random.Random(20261030)
now = time.time()
today = date.today()


def local(day, h, m=0):
    return int(time.mktime(datetime(day.year, day.month, day.day, h, m).timetuple()))


def bpm(hour):
    # asleep, then a calm day with an evening peak
    if hour < 6.5:
        base = 55 + 3 * math.sin(hour)
    else:
        base = 68 + 8 * math.sin((hour - 6.5) / 17 * math.pi)
    return int(round(base + rnd.uniform(-3, 3)))


def hr_day(day, until=None, workout=None, gap=None, start_h=0, end_h=24):
    lines = []
    t = local(day, start_h)
    end = local(day + timedelta(days=1), 0) if end_h == 24 else local(day, end_h)
    if until is not None:
        end = min(end, until)
    while t < end:
        h = datetime.fromtimestamp(t).hour + datetime.fromtimestamp(t).minute / 60
        if gap and gap[0] <= h < gap[1]:
            t += 600
            continue
        if workout and workout[0] <= h < workout[1]:
            v = int(118 + 30 * math.sin((h - workout[0]) / (workout[1] - workout[0]) * math.pi) + rnd.uniform(-4, 4))
            lines.append("%d:%d" % (t, v))
            t += 60
            continue
        lines.append("%d:%d" % (t, bpm(h)))
        t += 600
    return lines


def steps_day(day, total, until=None):
    # walked in the daytime hours, logged every 10 minutes as the day's count so far
    weights = [0] * 7 + [3, 6, 2, 2, 3, 5, 3, 2, 2, 3, 6, 4, 3, 2, 1, 0, 0]
    lines = []
    count = 0
    t = local(day, 0)
    end = local(day + timedelta(days=1), 0)
    if until is not None:
        end = min(end, until)
    per_slot = [total * w / sum(weights) / 6 for w in weights]
    while t < end:
        h = datetime.fromtimestamp(t).hour
        count += int(per_slot[h] * rnd.uniform(0.6, 1.4))
        if per_slot[h] > 0:
            lines.append("%d:%d" % (t, count))
        t += 600
    return lines


def write(d, day, lines):
    with open(os.path.join(d, day.isoformat() + ".log"), "w") as f:
        f.write("".join(line + "\n" for line in lines))


D = [today - timedelta(days=i) for i in range(7)]
recent = int(now - (3 * 3600 if mode == "stale" else 300))
if mode == "empty":
    for extra in ("sleep",):
        os.makedirs(os.path.join(root, extra), exist_ok=True)
    print("fixtures in", root, "(empty)")
    sys.exit(0)
write(hr_dir, D[0], ["%d:40" % (local(D[0], 0) - 600), "garbage", "%d:0" % local(D[0], 3), "%d:300" % local(D[0], 4),
                     "%d:x" % local(D[0], 5), ":61", "%d:24" % local(D[0], 5, 30)]
      + hr_day(D[0], until=recent, workout=(7.0, 7.67), gap=(12.5, 13.5)) + ["%d:%d" % (recent, 100)])
write(st_dir, D[0], steps_day(D[0], 6240, until=recent))
write(hr_dir, D[1], hr_day(D[1], workout=(18.0, 18.75)))
write(st_dir, D[1], steps_day(D[1], 8240))
# D[2]: not worn, no files
write(hr_dir, D[3], ["garbage", "", ":71", "%d:" % local(D[3], 9), "%d:7x" % local(D[3], 9, 30)]
      + hr_day(D[3], start_h=10, end_h=18) + ["17684"])
write(st_dir, D[3], steps_day(D[3], 4100))
write(hr_dir, D[4], ["%d:77" % local(D[4], 9, 12)])
write(st_dir, D[4], ["%d:350" % local(D[4], 9, 12)])
write(hr_dir, D[5], hr_day(D[5], workout=(17.0, 18.0)))
write(st_dir, D[5], steps_day(D[5], 12034))
write(hr_dir, D[6], hr_day(D[6]))
write(st_dir, D[6], steps_day(D[6], 6500))

# tst_data.qml: a fixed day whose file has every kind of bad line
J = date(2026, 1, 15)
t0 = local(J, 12)
write(hr_dir, J, ["%d:64" % t0, "", "garbage", ":70", "%d:" % (t0 + 600), "%d:7x" % (t0 + 1200),
                  "abc:70", "%d:65.5" % (t0 + 1800), "%d:0" % (t0 + 2400), "%d:66" % (t0 + 3000),
                  "%d" % (t0 + 3600)])  # the last line torn by a power loss
write(st_dir, J, ["%d:100" % t0, "x", "%d:250" % (t0 + 3600), "%d:240" % (t0 + 7200), "%d:900" % (t0 + 10800)])

# heartrate.db: the readings of the day files (valid ones), 3 = good accuracy
db_path = os.path.join(root, "heartrate.db")
if os.path.exists(db_path):
    os.unlink(db_path)
db = sqlite3.connect(db_path)
db.execute("CREATE TABLE IF NOT EXISTS heartrate (time INTEGER PRIMARY KEY, bpm INTEGER NOT NULL, accuracy INTEGER NOT NULL)")
db.execute("PRAGMA user_version=1")
for day in (D[0], D[1], D[5], D[6]):
    with open(os.path.join(hr_dir, day.isoformat() + ".log")) as f:
        for line in f:
            a = line.strip().split(":")
            if len(a) == 2 and a[0].isdigit() and a[1].isdigit() and 25 <= int(a[1]) <= 250:
                db.execute("INSERT OR IGNORE INTO heartrate VALUES (?, ?, 3)", (int(a[0]) * 1000, int(a[1])))
db.commit()
db.close()

# health.db: sensorlogd's daily rows (its store/healthDb.h; the columns the readers take), with the
# resting heart rate it estimated once for each day
hdb_path = os.path.join(root, "health.db")
for suffix in ("", "-wal", "-shm"):
    if os.path.exists(hdb_path + suffix):
        os.unlink(hdb_path + suffix)
hdb = sqlite3.connect(hdb_path)
hdb.execute("CREATE TABLE meta (key TEXT PRIMARY KEY, value)")
hdb.execute("CREATE TABLE daily (date TEXT PRIMARY KEY, resting_hr INTEGER, hrv_rmssd REAL, resp_rate REAL, "
            "temp_dev_c REAL, steps INTEGER, kcal REAL, distance_m REAL, floors INTEGER, azm INTEGER, "
            "hours_met INTEGER, cardio_load REAL, readiness INTEGER, closed_ms INTEGER, seq INTEGER NOT NULL DEFAULT 0)")
for n, (k, bpm) in enumerate(((0, 52), (1, 54), (3, 55), (5, 53), (6, 51))):
    hdb.execute("INSERT INTO daily (date, resting_hr, seq) VALUES (?, ?, ?)", (D[k].isoformat(), bpm, n + 1))
hdb.execute("INSERT INTO meta VALUES ('seq', 5)")
hdb.execute("PRAGMA user_version=1")
hdb.commit()
hdb.close()

# last night: yesterday 23:10 to today 06:40
sl_dir = os.path.join(root, "sleep")
os.makedirs(sl_dir, exist_ok=True)
for f in os.listdir(sl_dir):
    os.unlink(os.path.join(sl_dir, f))
night = {"version": 1, "valid": True, "wakeDate": D[0].isoformat(),
         "main": {"start": local(D[1], 23, 10) * 1000.0, "end": local(D[0], 6, 40) * 1000.0, "asleep": 420, "awake": 30,
                  "rem": 90, "light": 240, "deep": 90, "avgHr": 54.5},
         "naps": [], "score": 83, "scoreLabel": "Good", "goalMin": 480, "goalMet": False, "napMin": 0}
with open(os.path.join(sl_dir, D[0].isoformat() + ".json"), "w") as f:
    json.dump(night, f)

with open(os.path.join(home, ".config", "asteroid", "sensorlogd.conf"), "w") as f:
    f.write("[stepCounter]\ngoal0\\enabled=true\ngoal0\\target=8000\n")
print("fixtures in", root, "today", today.isoformat(), "now", datetime.fromtimestamp(now).strftime("%H:%M"))
