# the directory where all simulation output dirs are under.
# Since we use one sim to drive another, and we don't want to
# erase long runs.
# By default the data directory is under the build directory, as would
# be expected to avoid data state in a CI system.
# Developers may choose to use a directory outside the build directory
# to avoid redownloading data when intensively developing GemCI.
# The latter behavior runs the risk of data state where a bug isn't
# realized due to something in locally cached data.
if(NOT GEMINI_CIROOT AND DEFINED ENV{GEMINI_CIROOT})
  set(GEMINI_CIROOT $ENV{GEMINI_CIROOT})
endif()

if(NOT GEMINI_CIROOT)
  set(GEMINI_CIROOT ${CMAKE_CURRENT_BINARY_DIR})
endif()

file(REAL_PATH ${GEMINI_CIROOT} GEMINI_CIROOT EXPAND_TILDE)
