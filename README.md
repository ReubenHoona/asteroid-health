# Asteroid-health
The Health app of the watch, a frontend for the data collected by sensorlogd, built as stock's Google Health on Wear OS has it, and Relax, the guided breathing app.

# Health
A black page with the main goal ring and a card for each metric in stock's order: Steps, Energy burned, Distance, Floors, Active Zone Minutes, Hourly activity, Heart rate, Resting heart rate, Sleep and Skin temp variation, in the category colours of stock (FITNESS teal, HEALTH blue, WELLNESS lilac). A card opens the page of its metric:
* steps: today by the hour, the last 7 days with the goal line, the average, the best day and the best hour
* heart rate: the live rate (the sensor runs only while the page is shown), today's range, a line chart of today, the minutes in each heart rate zone and the zones of the week
* resting heart rate: today, the 7-day average and a 7-day line chart; a day's value is sensorlogd's, estimated once a day as stock's is (`HealthMetricsLoader.restingHrOf`, health.db `daily.resting_hr`)
* energy, distance, floors, Active Zone Minutes and hourly activity: today and the week
* sleep: last night's time asleep, the score, bedtime and wake-up time, the stages and naps
* skin temp variation: the morning's skin temperature variation against the personal range as stock words it (In range, Above range, Below range; "Wear to sleep N more times" while the baseline of 3 nights is made; Tracking… asleep, Analyzing… just after), the week's nights against the range and "In range this week"; in deg C, or deg F with the watch's temperature unit. The values are sensorlogd's (`HealthMetricsLoader.skinTemp`, `skinTempWeek`; health.db `skin_temp_night`), sampled only inside a night's sleep

Times follow the 12/24-hour setting (Settings > System > Date & time). Settings (the last row of the list) has the daily step goal, Reminders to move and the high and low heart rate alerts; changes apply at once. Logging switches and intervals are for developers (Settings > Developer options on, then Settings > Logging).

The Morning Brief page (greeting, today's weather, last night's sleep, yesterday's steps) opens with the open key below. Pages open from outside by writing `<page>@<time in ms>` to the dconf key `/org/asteroidos/health/ui/open` before launching the app: `heartrate`, `steps`, `energy`, `distance`, `floors`, `azm`, `hourly`, `resting`, `sleep`, `skintemp`, `morning`, `settings`.

The figures come from sensorlogd's QML plugin (HealthMetricsLoader, SleepDataLoader, LoggerSettings): distance, energy, floors, zones, Active Zone Minutes and hourly activity are estimates from steps and heart rate and the health profile (Settings).

# Relax
Launcher entry `asteroid-relax`: Breathe (1 to 15 minutes, 2 by default), a session of two blobs that swap size every 5 seconds with Inhale / Exhale and a vibration ramp for each phase (the switch is in Session settings), then a recap with the start and end heart rate and a mood. Sessions are written to sensorlogd's directory (`relax/<day>.log`: `time:seconds:start heart rate:end heart rate`, `mood/<day>.log`: `time:mood`).

## Tests
`tests/` holds the QML tests (run under qemu with the image's Qt, see the package notes), the fixtures (`make-fixtures.py`, fictional) and the host test of RelaxLog (`tst_relaxlog.cpp`).

## Translations

The app supports internationalization (i18n) and localization (l10n). All user-facing strings are translatable using Qt's translation system.

For information about contributing translations or adding new languages, see [i18n/README.md](i18n/README.md). `asteroid-health.en.ts` and `asteroid-relax.en.ts` are generated from the `//%` source texts of the QML files with lupdate.

## Getting your data
It should be obvious from a quick search of this source code that neither the app nor the logger contain any way to leak your data onto the internet. Your data is yours to keep: here's how you can get to it.

Data is stored in plaintext in ~/.asteroid-sensorlogd/ . There are separate directories for each sensor, and within those are separate file for each day.

Each line in a file is a single recording, in the format `[seconds since UNIX epoch]:[value]`.
