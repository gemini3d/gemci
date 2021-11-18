include(ExternalProject)

set(gemini_args
-DBUILD_TESTING:BOOL=off
-Dmsis2:BOOL=on
--install-prefix=${PROJECT_BINARY_DIR}
-DCMAKE_BUILD_TYPE=Debug
)

file(READ ${PROJECT_SOURCE_DIR}/libraries.json _libj)
string(JSON gemini_url GET ${_libj} gemini3d url)
string(JSON gemini_tag GET ${_libj} gemini3d tag)

ExternalProject_Add(GEMINI3D
GIT_REPOSITORY ${gemini_url}
GIT_TAG ${gemini_tag}
CMAKE_ARGS ${gemini_args}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

ExternalProject_Get_property(GEMINI3D SOURCE_DIR)
cmake_path(NORMAL_PATH SOURCE_DIR OUTPUT_VARIABLE GEMINI_ROOT)

set(GEMINI_RUN_DEBUG ${PROJECT_BINARY_DIR}/bin/gemini3d.run.debug)
set(GEMINI_RUN ${PROJECT_BINARY_DIR}/bin/gemini3d.run)
set(GEMINI_COMPARE ${PROJECT_BINARY_DIR}/bin/gemini3d.compare)
set(GEMINI_RUN_BOUNDS_CHECK true CACHE BOOL "assume flags OK on self-build")
