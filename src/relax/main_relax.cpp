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

#include <QtQml>
#include <asteroidapp.h>

#include "relaxlog.h"

// Relax, the breathing app: asteroid-relax.so (the launcher entry 'Relax')
int main(int argc, char *argv[])
{
    qmlRegisterType<RelaxLog>("org.asteroid.relax", 1, 0, "RelaxLog");
    return AsteroidApp::main(argc, argv);
}
