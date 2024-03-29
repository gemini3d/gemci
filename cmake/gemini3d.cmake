# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

set(extproj_args
USES_TERMINAL_DOWNLOAD true
USES_TERMINAL_UPDATE true
USES_TERMINAL_PATCH true
USES_TERMINAL_CONFIGURE true
USES_TERMINAL_BUILD true
USES_TERMINAL_INSTALL true
USES_TERMINAL_TEST true)

set(gemini_args
-DBUILD_TESTING:BOOL=off
-Dglow:BOOL=${glow}
-Dhwm14:BOOL=${hwm14}
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

# FIXME: would write a file with ExternalProject_AddStep
set(GEMINI_FEATURES "REALBITS:64" MPI HDF5)
if(glow)
  list(APPEND GEMINI_FEATURES GLOW)
endif()
if(msis2)
  list(APPEND GEMINI_FEATURES MSIS2)
endif()
if(hwm14)
  list(APPEND GEMINI_FEATURES HWM14)
endif()

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json lib_json)
string(JSON gemini3d_url GET ${lib_json} gemini3d url)
if(NOT gemini3d_tag)
  string(JSON gemini3d_tag GET ${lib_json} gemini3d tag)
endif()
message(STATUS "Gemini3D Git: ${gemini3d_tag}")

ExternalProject_Add(GEMINI3D_DEBUG
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Debug
CONFIGURE_HANDLED_BY_BUILD true
${extproj_args}
)

set(GEMINI_RUN_DEBUG ${PROJECT_BINARY_DIR}/bin/gemini3d.run.debug)
set(GEMINI_Fortran_BIN_DEBUG ${PROJECT_BINARY_DIR}/bin/gemini.bin.debug)
set(GEMINI_CXX_BIN_DEBUG ${PROJECT_BINARY_DIR}/bin/gemini_c.bin.debug)


ExternalProject_Add(GEMINI3D_RELEASE
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Release
CONFIGURE_HANDLED_BY_BUILD true
DEPENDS GEMINI3D_DEBUG
${extproj_args}
)
# DEPENDS debug to help ensure order of build, not specific dependency

ExternalProject_Get_property(GEMINI3D_RELEASE BINARY_DIR)
set(GEMINI_RUN ${PROJECT_BINARY_DIR}/bin/gemini3d.run)
set(GEMINI_Fortran_BIN ${PROJECT_BINARY_DIR}/bin/gemini.bin)
set(GEMINI_COMPARE ${PROJECT_BINARY_DIR}/bin/gemini3d.compare)
set(GEMINI_CXX_BIN ${PROJECT_BINARY_DIR}/bin/gemini_c.bin)
