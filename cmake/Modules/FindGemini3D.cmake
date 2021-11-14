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

string(REPLACE " " ";" _f ${_f})
set(gemini_features)
foreach(f ${_f})
  string(STRIP "${f}" f)
  if(f)
    list(APPEND gemini_features ${f})
  endif()
endforeach()
set(GEMINI_FEATURES ${gemini_features} CACHE STRING "GEMINI3D Features")

endif()
# --- detailed check
if(NOT GEMINI_RUN_DEBUG)
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
      set(GEMINI_RUN_BOUNDS_CHECK true CACHE BOOL "gemini3d.debug.run with bounds checking")
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
HINTS ${GEMINI_ROOT} ENV GEMINI_ROOT
PATHS ${PROJECT_SOURCE_DIR}/../gemini3d
PATH_SUFFIXES Release RelWithDebInfo Debug build/Release build/RelWithDebInfo build/Debug build bin
NO_DEFAULT_PATH
DOC "Gemini3d.run Fortran front-end"
)

find_program(GEMINI_RUN_DEBUG
NAMES gemini3d.run.debug
HINTS ${GEMINI_ROOT} ENV GEMINI_ROOT
PATHS ${PROJECT_SOURCE_DIR}/../gemini3d
PATH_SUFFIXES Debug build/Debug build bin
NO_DEFAULT_PATH
DOC "Gemini3d.run Fortran front-end: debugging enabled"
)

# determine if exe has Fortran bounds checking.
# currently, we handle GCC and Intel/IntelLLVM.
if(GEMINI_RUN AND NOT DEFINED GEMINI_RUN_BOUNDS_CHECK)
  check_gemini_feature()
endif()

# --- find gemini.compare
find_program(GEMINI_COMPARE
NAMES gemini3d.compare
HINTS ${GEMINI_ROOT} ENV GEMINI_ROOT
PATHS ${PROJECT_SOURCE_DIR}/../gemini3d
PATH_SUFFIXES build bin build/Release build/RelWithDebInfo build/Debug
NO_DEFAULT_PATH
DOC "Gemini3d.compare data"
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gemini3D
REQUIRED_VARS GEMINI_RUN GEMINI_COMPARE
)
