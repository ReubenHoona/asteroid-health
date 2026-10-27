#!/bin/sh
# Coverage of src/cpp/lineGraph_p.{cpp,h} (the line graph; eos: an empty range clears it) from tests/linegraph.
# The QML (heart rate preview/graph pages) is not analysed by SonarQube.
# Run by ~/stacks/sonarqube/scan.sh in the image from .sonar/Dockerfile, cwd = the repository root.
# Local run: sh .sonar/coverage.sh (needs Qt 6 Quick/Test, cmake, gcc, gcovr); report .sonar-reports/cobertura.xml.
set -eu
out=.sonar-reports
build=$out/build
rm -rf "$build"
mkdir -p "$build"
cmake -S tests/linegraph -B "$build" -DLINEGRAPH_COVERAGE=ON -DCMAKE_BUILD_TYPE=Debug > "$build/cmake.log"
cmake --build "$build" -j "${JOBS:-1}"
(cd "$build" && QT_QPA_PLATFORM=offscreen ./tst_linegraph)
gcovr --root . --filter 'src/cpp/lineGraph_p\.(cpp|h)$' --object-directory "$build" \
  --exclude-unreachable-branches --cobertura "$out/cobertura.xml" --txt "$out/coverage.txt" "$build"
cat "$out/coverage.txt"
