# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

if(NOT GEMINI_ROOT)
  set(GEMINI_ROOT ${CMAKE_INSTALL_PREFIX})
endif()

set(gemini_args
-DBUILD_TESTING:BOOL=off
-Dmpi:BOOL=on
-Dmsis2:BOOL=on
-Dglow:BOOL=on
-Dhdf5:BOOL=on
-Dhwm14:BOOL=on
-Dnetcdf:BOOL=off
--install-prefix=${GEMINI_ROOT}
)

ExternalProject_Add(GEMINI3D_RELEASE
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Release
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

ExternalProject_Get_property(GEMINI3D_RELEASE SOURCE_DIR)

ExternalProject_Add(GEMINI3D_DEBUG
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Debug
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

set(GEMINI_RUN ${GEMINI_ROOT}/bin/gemini3d.run)
set(GEMINI_RUN_DEBUG ${GEMINI_ROOT}/bin/gemini3d.run.debug)

set(GEMINI_BIN ${GEMINI_ROOT}/bin/gemini.bin)
set(GEMINI_BIN_DEBUG ${GEMINI_ROOT}/bin/gemini.bin.debug)

set(GEMINI_COMPARE ${GEMINI_ROOT}/bin/gemini3d.compare)
# there doesn't seem to be an easy way to run "gemini3d.run -features" and capture output
# via ExternalProject without using auxiliary files.
set(GEMINI_FEATURES "REALBITS:64 MPI GLOW MSIS2 HDF5 HWM14")
set(GEMINI_RUN_BOUNDS_CHECK true CACHE BOOL "assume bounds flags OK on self-build")

# --- Git metadata
set(_max_len 80)
# so as not to exceed maximum 132 character Fortran line length.

# this is ordinarily compiled into gemini executable, but as above not an easy way to run and capture
# after externalproject build except by Add_Step() and auxiliary file.
execute_process(COMMAND ${GIT_EXECUTABLE} describe --tags
WORKING_DIRECTORY ${SOURCE_DIR}
OUTPUT_VARIABLE GEMINI_VERSION
OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE _err
TIMEOUT 10
)
if(NOT _err EQUAL 0)
  # old Git
  execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
  WORKING_DIRECTORY ${SOURCE_DIR}
  OUTPUT_VARIABLE GEMINI_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE _err
  TIMEOUT 10
  )
endif()
if(_err EQUAL 0)
  string(SUBSTRING ${GEMINI_VERSION} 0 ${_max_len} GEMINI_VERSION)
else()
  set(GEMINI_VERSION)
endif()
