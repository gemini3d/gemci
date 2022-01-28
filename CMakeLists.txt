# for robustness, uses CMake superproject layout, where:
#
# 1. ExternalProject(Gemini3D)  # Gemini3D program build
# 2. ExternalProject(CI)  # CI program
#
# To run tests, command like:
#
#   ctest --test-dir build/gemci

cmake_minimum_required(VERSION 3.20...3.22)

project(GemCI
LANGUAGES NONE
HOMEPAGE_URL https://github.com/gemini3d/gemci
DESCRIPTION "Long-running Gemini3D test cases"
VERSION 0.1.0)

include(cmake/options.cmake)
include(cmake/libraries.cmake)

include(cmake/gemini3d.cmake)
include(cmake/gemci.cmake)
