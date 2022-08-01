# for robustness, uses CMake superproject layout.
# To run tests:
#
#   ctest --preset default
# or
#   ctest --test-dir build/gemci

cmake_minimum_required(VERSION 3.21...3.24)

project(GemCI
LANGUAGES C CXX Fortran
HOMEPAGE_URL https://github.com/gemini3d/gemci
DESCRIPTION "Long-running Gemini3D test cases"
VERSION 1.0.0
)

include(CTest)

include(cmake/options.cmake)

# Gemini3D ExternalProject
include(cmake/gemini3d.cmake)

# GemCI ExternalProject

# GEMINI_CIROOT at initial superproject configure for better UX (it's orthogonal to Gemini3D)
include(${PROJECT_SOURCE_DIR}/cmake/get_simroot.cmake)
message(STATUS "simulation root directory ${GEMINI_CIROOT}")

add_subdirectory(src)
