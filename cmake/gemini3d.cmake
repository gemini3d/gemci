# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

set(gemini_args
-DBUILD_TESTING:BOOL=off
-Dmpi:BOOL=on
-Dmsis2:BOOL=${msis2}
-Dglow:BOOL=${glow}
-Dhdf5:BOOL=on
-Dhwm14:BOOL=${hwm14}
-Dnetcdf:BOOL=off
-Dcpp:BOOL=on
-DCMAKE_INSTALL_PREFIX:PATH=${PROJECT_BINARY_DIR}
-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
)
if(CMAKE_PREFIX_PATH)
  list(APPEND gemini_args -DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH})
endif()
if(MPI_ROOT)
  list(APPEND gemini_args -DMPI_ROOT:PATH=${MPI_ROOT})
endif()
# -DCMAKE_VERBOSE_MAKEFILE:BOOL=true

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json lib_json)
string(JSON gemini3d_url GET ${lib_json} gemini3d url)
if(gemini3d_tag)
  message(STATUS "overriding Gemini3D Git tag with ${gemini3d_tag}")
else()
  string(JSON gemini3d_tag GET ${lib_json} gemini3d tag)
endif()

ExternalProject_Add(GEMINI3D_DEBUG
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Debug
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

ExternalProject_Get_property(GEMINI3D_DEBUG BINARY_DIR)
cmake_path(SET GEMINI_RUN_DEBUG ${BINARY_DIR}/gemini3d.run.debug)
cmake_path(SET GEMINI_BIN_DEBUG ${BINARY_DIR}/gemini.bin.debug)

ExternalProject_Add(GEMINI3D_RELEASE
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Release
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
DEPENDS GEMINI3D_DEBUG
)
# DEPENDS debug to help ensure order of build, not specific dependency

ExternalProject_Get_property(GEMINI3D_RELEASE BINARY_DIR)
cmake_path(SET GEMINI_RUN ${BINARY_DIR}/gemini3d.run)
cmake_path(SET GEMINI_BIN ${BINARY_DIR}/gemini.bin)
cmake_path(SET GEMINI_COMPARE ${BINARY_DIR}/gemini3d.compare)
