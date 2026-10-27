# Host test of LineGraph_p (src/cpp/lineGraph_p.cpp): painted into a QImage, no window. Used by
# .sonar/coverage.sh; locally:
#   cmake -S tests/linegraph -B build-tests && cmake --build build-tests && \
#   QT_QPA_PLATFORM=offscreen build-tests/tst_linegraph
cmake_minimum_required(VERSION 3.19)
project(tst_linegraph LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Test)

set(CPP ${CMAKE_CURRENT_SOURCE_DIR}/../../src/cpp)
option(LINEGRAPH_COVERAGE "build with gcc --coverage" OFF)

add_executable(tst_linegraph tst_linegraph.cpp ${CPP}/lineGraph_p.cpp ${CPP}/lineGraph_p.h)
target_include_directories(tst_linegraph PRIVATE ${CPP})
target_link_libraries(tst_linegraph PRIVATE Qt::Core Qt::Gui Qt::Quick Qt::Test)
if(LINEGRAPH_COVERAGE)
    target_compile_options(tst_linegraph PRIVATE --coverage -O0 -g)
    target_link_options(tst_linegraph PRIVATE --coverage)
endif()

enable_testing()
add_test(NAME tst_linegraph COMMAND tst_linegraph)
set_tests_properties(tst_linegraph PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
