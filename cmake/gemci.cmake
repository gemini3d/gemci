# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

set(gemci_args
-Dequil:BOOL=${equil}
-Dpackage:BOOL=${package}
-Dpython:BOOL=${python}
-Dmatlab:BOOL=${matlab}
-Dplotdiff:bool=${plotdiff}
-DGEMINI_ROOT:PATH=${PROJECT_BINARY_DIR}/bin
-DGEMINI_CIROOT:PATH=${GEMINI_CIROOT}
)
if(CMAKE_PREFIX_PATH)
  list(APPEND gemci_args -DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH})
endif()


ExternalProject_Add(GEMCI
SOURCE_DIR ${PROJECT_SOURCE_DIR}/src
BINARY_DIR ${PROJECT_BINARY_DIR}/gemci
CMAKE_ARGS ${gemci_args}
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
BUILD_COMMAND ""
INSTALL_COMMAND ""
TEST_COMMAND ""
CONFIGURE_HANDLED_BY_BUILD true
DEPENDS "GEMINI3D_RELEASE;GEMINI3D_DEBUG"
)
