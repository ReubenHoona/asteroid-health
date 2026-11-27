/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

.pragma library

/*
 * The names of the Exercise app's 54 exercise types (asteroid-exercise src/ExerciseTypes.js, stock's FitbitExerciseType
 * names 0x7f140578-0x7f1405af) by the key health.db stores (sensorlogd's workout.type), with the app's own text ids.
 * Made by gen_exnames.py from the app's list: change that, not this.
 */

function name(key) {
    switch (String(key)) {
    //% "Aerobics"
    case "Aerobics": return qsTrId("id-ex-type-aerobics")
    //% "Badminton"
    case "Badminton": return qsTrId("id-ex-type-badminton")
    //% "Baseball"
    case "Baseball": return qsTrId("id-ex-type-baseball")
    //% "Basketball"
    case "Basketball": return qsTrId("id-ex-type-basketball")
    //% "Bike"
    case "Bike": return qsTrId("id-ex-type-bike")
    //% "Bootcamp"
    case "BootCamp": return qsTrId("id-ex-type-bootcamp")
    //% "Canoeing"
    case "Canoeing": return qsTrId("id-ex-type-canoeing")
    //% "Circuit training"
    case "CircuitTraining": return qsTrId("id-ex-type-circuittraining")
    //% "Core training"
    case "CoreTraining": return qsTrId("id-ex-type-coretraining")
    //% "Cricket"
    case "Cricket": return qsTrId("id-ex-type-cricket")
    //% "Cross-country skiing"
    case "CrossCountrySki": return qsTrId("id-ex-type-crosscountryski")
    //% "CrossFit"
    case "Crossfit": return qsTrId("id-ex-type-crossfit")
    //% "Dancing"
    case "Dance": return qsTrId("id-ex-type-dance")
    //% "Elliptical"
    case "Elliptical": return qsTrId("id-ex-type-elliptical")
    //% "Field hockey"
    case "FieldHockey": return qsTrId("id-ex-type-fieldhockey")
    //% "Football"
    case "Football": return qsTrId("id-ex-type-football")
    //% "Golf"
    case "Golf": return qsTrId("id-ex-type-golf")
    //% "HIIT"
    case "HIIT": return qsTrId("id-ex-type-hiit")
    //% "Hike"
    case "Hike": return qsTrId("id-ex-type-hike")
    //% "Indoor climbing"
    case "IndoorClimbing": return qsTrId("id-ex-type-indoorclimbing")
    //% "Interval workout"
    case "IntervalWorkout": return qsTrId("id-ex-type-intervalworkout")
    //% "Kayaking"
    case "Kayaking": return qsTrId("id-ex-type-kayaking")
    //% "Kickboxing"
    case "Kickboxing": return qsTrId("id-ex-type-kickboxing")
    //% "Martial arts"
    case "MartialArts": return qsTrId("id-ex-type-martialarts")
    //% "Mountain Biking"
    case "MountainBiking": return qsTrId("id-ex-type-mountainbiking")
    //% "Outdoor workout"
    case "OutdoorWorkout": return qsTrId("id-ex-type-outdoorworkout")
    //% "Swim - Open"
    case "OpenWaterSwim": return qsTrId("id-ex-type-openwaterswim")
    //% "Pickleball"
    case "Pickleball": return qsTrId("id-ex-type-pickleball")
    //% "Padel"
    case "Padel": return qsTrId("id-ex-type-padel")
    //% "Pilates"
    case "Pilates": return qsTrId("id-ex-type-pilates")
    //% "Swim - Pool"
    case "PoolSwim": return qsTrId("id-ex-type-poolswim")
    //% "Powerlifting"
    case "Powerlifting": return qsTrId("id-ex-type-powerlifting")
    //% "Rollerblading"
    case "Rollerblading": return qsTrId("id-ex-type-rollerblading")
    //% "Rowing machine"
    case "RowingMachine": return qsTrId("id-ex-type-rowingmachine")
    //% "Rugby"
    case "Rugby": return qsTrId("id-ex-type-rugby")
    //% "Run"
    case "Run": return qsTrId("id-ex-type-run")
    //% "Skating"
    case "Skating": return qsTrId("id-ex-type-skating")
    //% "Skiing"
    case "Skiing": return qsTrId("id-ex-type-skiing")
    //% "Snowboarding"
    case "Snowboarding": return qsTrId("id-ex-type-snowboarding")
    //% "Soccer"
    case "Soccer": return qsTrId("id-ex-type-soccer")
    //% "Spinning"
    case "Spinning": return qsTrId("id-ex-type-spinning")
    //% "Sport"
    case "Sport": return qsTrId("id-ex-type-sport")
    //% "Stair climber"
    case "StairClimber": return qsTrId("id-ex-type-stairclimber")
    //% "Strength training"
    case "StrengthTraining": return qsTrId("id-ex-type-strengthtraining")
    //% "Paddleboarding"
    case "SUP": return qsTrId("id-ex-type-sup")
    //% "Surfing"
    case "Surfing": return qsTrId("id-ex-type-surfing")
    //% "Swim"
    case "Swim": return qsTrId("id-ex-type-swim")
    //% "Tennis"
    case "Tennis": return qsTrId("id-ex-type-tennis")
    //% "Treadmill"
    case "TreadMill": return qsTrId("id-ex-type-treadmill")
    //% "Walk"
    case "Walk": return qsTrId("id-ex-type-walk")
    //% "Weightlifting"
    case "Weightlifting": return qsTrId("id-ex-type-weightlifting")
    //% "Weights"
    case "Weights": return qsTrId("id-ex-type-weights")
    //% "Workout"
    case "Workout": return qsTrId("id-ex-type-workout")
    //% "Yoga"
    case "Yoga": return qsTrId("id-ex-type-yoga")
    }
    // a key this list does not know: the key itself
    return String(key)
}
