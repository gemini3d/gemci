# in general, we need both Release and Debug of Gemini3D.
# to ensure this happens without requiring Ninja Multi-Config, we do two distinct builds
# with the same install directory.
include(ExternalProject)

set(GEMCI_ROOT ${PROJECT_BINARY_DIR})

set(gemci_args
-Dequil:BOOL=${equil}
-Dpackage:BOOL=${package}
-Dpython:BOOL=${python}
-Dmatlab:BOOL=${matlab}
-DGEMINI_ROOT:PATH=${GEMINI_ROOT}
)
# --debug-find

message(STATUS "${GEMINI3D_BINARY_DIR_RELEASE}")

ExternalProject_Add(GEMCI
SOURCE_DIR ${PROJECT_SOURCE_DIR}/src
BINARY_DIR ${PROJECT_BINARY_DIR}/gemci
CMAKE_ARGS ${gemci_args}
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INSTALL_COMMAND ""
TEST_COMMAND ""
CONFIGURE_HANDLED_BY_BUILD true
DEPENDS GEMINI3D_RELEASE GEMINI3D_DEBUG
LOG_TEST true
)
