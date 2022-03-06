# Find Gemini3d and test its capabilities

function(check_gemini_feature)

# --- feature flags

execute_process(COMMAND ${GEMINI_RUN} -features
TIMEOUT 5
RESULT_VARIABLE ret
OUTPUT_VARIABLE _f
OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(ret EQUAL 0)
  separate_arguments(_f)
  set(GEMINI_FEATURES ${_f} CACHE STRING "GEMINI3D Features")
endif()

# --- version
if(NOT DEFINED CACHE{GEMINI_VERSION})
  execute_process(COMMAND ${GEMINI_RUN} -git
  OUTPUT_VARIABLE GEMINI_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  TIMEOUT 5
  COMMAND_ERROR_IS_FATAL ANY
  )
  set(GEMINI_VERSION ${GEMINI_VERSION} CACHE STRING "GEMINI3D Version")
endif()

# --- compiler version
if(NOT DEFINED CACHE{GEMINI_Fortran_COMPILER_VERSION})
  execute_process(COMMAND ${GEMINI_RUN} -compiler_version
  OUTPUT_VARIABLE GEMINI_Fortran_COMPILER_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  TIMEOUT 5
  COMMAND_ERROR_IS_FATAL ANY
  )
  set(GEMINI_Fortran_COMPILER_VERSION ${GEMINI_Fortran_COMPILER_VERSION} CACHE STRING "GEMINI Fortran Compiler Version")
endif()

# --- detailed check
if(NOT GEMINI_RUN_DEBUG AND GEMINI_BIN_DEBUG)
  return()
endif()

execute_process(COMMAND ${GEMINI_RUN_DEBUG} -compiler
TIMEOUT 5
RESULT_VARIABLE ret
OUTPUT_VARIABLE _comp_name
OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(NOT ret EQUAL 0)
  message(WARNING "${GEMINI_RUN_DEBUG} failed essential self-check. Was it compiled for this computer?")
  return()
endif()


if(_comp_name STREQUAL GNU)
  set(_flags_exp "-fcheck=all;-fcheck=bounds")
elseif(_comp_name MATCHES "^Intel")
  set(_flags_exp "-check;-CB;/check;/CB")
else()
  message(STATUS "${_comp_name} not known flags for bounds check")
  return()
endif()

execute_process(COMMAND ${GEMINI_RUN_DEBUG} -compiler_options
TIMEOUT 5
RESULT_VARIABLE ret
OUTPUT_VARIABLE _comp_opt
OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(ret EQUAL 0)
  foreach(s ${_flags_exp})
    if(_comp_opt MATCHES ${s})
      set(GEMINI_RUN_BOUNDS_CHECK true CACHE BOOL "gemini3d.run.debug with bounds checking")
      return()
    endif()
  endforeach()
endif()

message(STATUS "Could not determine if ${GEMINI_RUN_DEBUG} was compiled with bounds checking. Assuming bounds checking disabled.")
set(GEMINI_RUN_BOUNDS_CHECK false CACHE BOOL "NOT FOUND")

endfunction(check_gemini_feature)


# --- main script ---

# --- find gemini frontend

find_program(GEMINI_RUN
NAMES gemini3d.run
HINTS ${GEMINI_ROOT}
PATH_SUFFIXES build/Release build bin
NO_DEFAULT_PATH
DOC "Gemini3d.run Fortran front-end"
)

if(NOT GEMINI_RUN_OK)
  execute_process(COMMAND ${GEMINI_RUN}
  TIMEOUT 5
  RESULT_VARIABLE ret
  OUTPUT_VARIABLE _out
  ERROR_VARIABLE _err
  )
  if(ret EQUAL 0)
    set(GEMINI_RUN_OK true CACHE BOOL "gemini3d.run basic check OK")
  else()
    set(GEMINI_RUN_OK false)
    message(STATUS "gemini3d.run basic check failed: ${_err}")
  endif()
endif()

find_program(GEMINI_BIN
NAMES gemini.bin
HINTS ${GEMINI_ROOT}
PATH_SUFFIXES build/Release build bin
NO_DEFAULT_PATH
DOC "Gemini.bin Fortran main program"
)


find_program(GEMINI_RUN_DEBUG
NAMES gemini3d.run.debug
HINTS ${GEMINI_ROOT}
PATH_SUFFIXES build/RelWithDebInfo build/Debug build bin
NO_DEFAULT_PATH
DOC "Gemini3d.run Fortran front-end: debug enabled"
)

find_program(GEMINI_BIN_DEBUG
NAMES gemini.bin.debug
HINTS ${GEMINI_ROOT}
PATH_SUFFIXES build/RelWithDebInfo build/Debug build bin
NO_DEFAULT_PATH
DOC "Gemini.bin Fortran main program: debug enabled"
)

# determine if exe has Fortran bounds checking.
# currently, we handle GCC and Intel/IntelLLVM.
if(GEMINI_RUN_OK AND NOT DEFINED GEMINI_RUN_BOUNDS_CHECK)
  check_gemini_feature()
endif()

# --- find gemini.compare
find_program(GEMINI_COMPARE
NAMES gemini3d.compare gemini3d.compare.debug
HINTS ${GEMINI_ROOT}
PATH_SUFFIXES build/Release build/RelWithDebInfo build/Debug build bin
NO_DEFAULT_PATH
DOC "Gemini3d.compare data"
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gemini3D
REQUIRED_VARS GEMINI_RUN GEMINI_COMPARE GEMINI_RUN_OK
)
