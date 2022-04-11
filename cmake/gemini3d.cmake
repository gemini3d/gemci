# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

set(gemini_args
-DBUILD_TESTING:BOOL=off
-Dmpi:BOOL=on
-Dmsis2:BOOL=off
-Dglow:BOOL=on
-Dhdf5:BOOL=on
-Dhwm14:BOOL=off
-Dnetcdf:BOOL=off
-DCMAKE_INSTALL_PREFIX:PATH=${PROJECT_BINARY_DIR}
)
if(CMAKE_PREFIX_PATH)
  list(APPEND gemini_args -DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH})
endif()
# -DCMAKE_VERBOSE_MAKEFILE:BOOL=true

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json lib_json)
string(JSON gemini3d_url GET ${lib_json} gemini3d url)
string(JSON gemini3d_tag GET ${lib_json} gemini3d tag)

ExternalProject_Add(GEMINI3D_DEBUG
GIT_REPOSITORY ${gemini3d_url}
GIT_TAG ${gemini3d_tag}
CMAKE_ARGS ${gemini_args} -DCMAKE_BUILD_TYPE=Debug
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
)

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
