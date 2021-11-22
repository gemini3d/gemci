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
-Dnetcdf:BOOL=off
--install-prefix=${GEMINI_ROOT}
)

file(READ ${PROJECT_SOURCE_DIR}/libraries.json _libj)
string(JSON gemini_url GET ${_libj} gemini3d url)
string(JSON gemini_tag GET ${_libj} gemini3d tag)

ExternalProject_Add(GEMINI3D_RELEASE
GIT_REPOSITORY ${gemini_url}
GIT_TAG ${gemini_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Release
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

ExternalProject_Add(GEMINI3D_DEBUG
GIT_REPOSITORY ${gemini_url}
GIT_TAG ${gemini_tag}
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
set(GEMINI_FEATURES "REALBITS:64 MPI GLOW MSIS2 HDF5")
set(GEMINI_RUN_BOUNDS_CHECK true CACHE BOOL "assume bounds flags OK on self-build")
