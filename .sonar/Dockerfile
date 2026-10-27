# Image for .sonar/coverage.sh: ~/stacks/sonarqube/scan.sh builds it (context: this .sonar/ directory only) and runs
# the script in it as the scanning user. A native x86_64 build of tests/linegraph (LineGraph_p painted into a QImage)
# against Debian's Qt 6 (Core, Gui, Quick, Test), gcc with --coverage, gcovr for the Cobertura report;
# the watch builds asteroid-health with the AsteroidOS SDK, which is not available here. The test runs on the
# offscreen platform. The base image is pinned; nothing is downloaded when the
# coverage runs.
FROM debian:trixie-20261005-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        g++ make cmake pkgconf \
        qt6-base-dev qt6-base-dev-tools qt6-declarative-dev \
        gcovr \
    && rm -rf /var/lib/apt/lists/*
