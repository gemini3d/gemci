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
-Dlow_ram=${low_ram}
)

message(STATUS "${GEMINI3D_BINARY_DIR_RELEASE}")

ExternalProject_Add(GEMCI
SOURCE_DIR ${PROJECT_SOURCE_DIR}/src
CMAKE_ARGS ${gemci_args}
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
INSTALL_COMMAND ""
TEST_COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${PROJECT_BINARY_DIR}/GEMCI-prefix/src/GEMCI-build
CONFIGURE_HANDLED_BY_BUILD true
DEPENDS GEMINI3D_RELEASE GEMINI3D_DEBUG
LOG_TEST true
)

ExternalProject_Get_Property(GEMCI BINARY_DIR)
