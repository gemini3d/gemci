# the directory where all simulation output dirs are under.
# Since we use one sim to drive another, and we don't want to
# erase long runs
if(NOT GEMINI_CIROOT AND DEFINED ENV{GEMINI_CIROOT})
  set(GEMINI_CIROOT $ENV{GEMINI_CIROOT})
endif()

if(NOT GEMINI_CIROOT)
  message(FATAL_ERROR "please specify GEMINI_CIROOT, either by:

  * set environment variable GEMINI_CIROOT
  * at configure time:  cmake -DGEMINI_CIROOT:PATH=/path/to/CI-data
  ")
endif()

if(CMAKE_VERSION VERSION_LESS 3.21)
  get_filename_component(GEMINI_CIROOT ${GEMINI_CIROOT} ABSOLUTE)
else()
  file(REAL_PATH ${GEMINI_CIROOT} GEMINI_CIROOT EXPAND_TILDE)
endif()
cmake_path(APPEND ref_root ${GEMINI_CIROOT} test_ref)

if(NOT IS_DIRECTORY ${GEMINI_CIROOT})
  file(MAKE_DIRECTORY ${GEMINI_CIROOT})
endif()

if(NOT IS_DIRECTORY ${ref_root})
  message("Creating reference data directory ${ref_root}")
  file(MAKE_DIRECTORY ${ref_root})
endif()
