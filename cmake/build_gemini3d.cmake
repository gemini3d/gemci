# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

if(NOT GEMINI_ROOT)
  set(GEMINI_ROOT ${CMAKE_INSTALL_PREFIX})
endif()

set(CMAKE_VERBOSE_MAKEFILE false)

set(gemini_args
-DBUILD_TESTING:BOOL=off
-Dmpi:BOOL=on
-Dmsis2:BOOL=on
-Dglow:BOOL=on
-Dhdf5:BOOL=on
-Dhwm14:BOOL=on
-Dnetcdf:BOOL=off
-DCMAKE_INSTALL_PREFIX=${GEMINI_ROOT}
-DCMAKE_VERBOSE_MAKEFILE:BOOL=${CMAKE_VERBOSE_MAKEFILE}
)

ExternalProject_Add(GEMINI3D_RELEASE
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Release
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

ExternalProject_Add(GEMINI3D_DEBUG
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Debug
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

set(GEMINI_RUN ${GEMINI_ROOT}/bin/gemini3d.run$<$<BOOL:${WIN32}>:.exe>)
set(GEMINI_RUN_DEBUG ${GEMINI_ROOT}/bin/gemini3d.run.debug$<$<BOOL:${WIN32}>:.exe>)

set(GEMINI_BIN ${GEMINI_ROOT}/bin/gemini.bin$<$<BOOL:${WIN32}>:.exe>)
set(GEMINI_BIN_DEBUG ${GEMINI_ROOT}/bin/gemini.bin.debug$<$<BOOL:${WIN32}>:.exe>)

set(GEMINI_COMPARE ${GEMINI_ROOT}/bin/gemini3d.compare$<$<BOOL:${WIN32}>:.exe>)
# there doesn't seem to be an easy way to run "gemini3d.run -features" and capture output
# via ExternalProject without using auxiliary files.
set(GEMINI_FEATURES "REALBITS:64;MPI;GLOW;MSIS2;HDF5;HWM14")
set(GEMINI_RUN_BOUNDS_CHECK true CACHE BOOL "assume bounds flags OK on self-build")

# get Git revision of Gemini3D via ExternalProject Step and log file
ExternalProject_Get_property(GEMINI3D_RELEASE STAMP_DIR)

ExternalProject_Add_Step(GEMINI3D_RELEASE git_version DEPENDEES build
COMMAND ${GEMINI_RUN} -git
LOG true
)
# logfile name: ${STAMP_DIR}/GEMINI3D_RELEASE-git_version-out.log
