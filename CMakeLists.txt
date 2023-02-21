cmake_minimum_required(VERSION 3.21...3.24)

project(GemCI
LANGUAGES C CXX Fortran
HOMEPAGE_URL https://github.com/gemini3d/gemci
DESCRIPTION "Long-running Gemini3D test cases"
VERSION 1.0.0
)

set(DART_TESTING_TIMEOUT 10000)
# set arbitrarily large timeout--must set DART_TESTING_TIMEOUT before CTest.
# This takes effect if --timeout or preset doesn't specify timeout.
include(CTest)

include(options.cmake)

# Gemini3D ExternalProject
include(cmake/gemini3d.cmake)

# GemCI ExternalProject

# GEMINI_CIROOT at initial superproject configure for better UX (it's orthogonal to Gemini3D)
include(cmake/get_simroot.cmake)
message(STATUS "simulation root directory ${GEMINI_CIROOT}")

# ensure needed libraries are available

find_program(MPIEXEC_EXECUTABLE
NAMES mpiexec
HINTS ${MPI_ROOT} ENV MPI_ROOT ENV I_MPI_ROOT
PATHS /usr/lib64
PATH_SUFFIXES bin openmpi/bin mpich/bin
DOC "Runs an MPI program"
REQUIRED
)

# --- helper functions
include(cmake/ParseNml.cmake)
include(cmake/GetEquil.cmake)
include(cmake/InputSetup.cmake)
include(cmake/ModelSetup.cmake)
include(cmake/GeminiRun.cmake)
include(cmake/GeminiCompare.cmake)
include(cmake/GeminiPlot.cmake)
include(cmake/GeminiPackage.cmake)

# --- top level directories
cmake_path(SET ci_root ${PROJECT_SOURCE_DIR}/cfg)
cmake_path(SET ref_root ${GEMINI_CIROOT}/test_ref)

# --- measure system physical RAM
cmake_host_system_information(RESULT host_ramMB QUERY TOTAL_PHYSICAL_MEMORY)

if(NOT DEFINED low_ram)
  set(low_ram false)
  if(host_ramMB LESS 18000)
    # 18 GB: the 3D Matlab plots use 9GB RAM each
    set(low_ram true)
  endif()
endif()

# --- PyGemini
if(python)
  include(${PROJECT_SOURCE_DIR}/cmake/python.cmake)
endif()

# --- MatGemini
if(matlab)
  include(${PROJECT_SOURCE_DIR}/cmake/matlab.cmake)
endif()
include(${PROJECT_SOURCE_DIR}/cmake/MatlabTest.cmake)

add_subdirectory(src)
