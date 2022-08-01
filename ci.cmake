cmake_minimum_required(VERSION 3.21)

set(CTEST_PROJECT_NAME "GemCI")

set(CTEST_LABELS_FOR_SUBPROJECTS "python;matlab")

set(gemini3d_url https://github.com/gemini3d/gemini3d.git)

option(cpp "use C++ Gemini3D frontend")
option(submit "use CDash upload" true)

set(opts
-Dcpp:BOOL=${cpp}
-Ddev:BOOL=no
-Dmatlab:BOOL=no
-Dpython:BOOL=yes
)
if(gemini3d_tag)
  list(APPEND opts -Dgemini3d_tag=${gemini3d_tag})
endif()
if(CMAKE_PREFIX_PATH)
  list(APPEND opts -DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH})
endif()
if(MPI_ROOT)
  list(APPEND opts -DMPI_ROOT:PATH=${MPI_ROOT})
endif()
if(GEMINI_CIROOT)
  list(APPEND opts -DGEMINI_CIROOT:PATH=${GEMINI_CIROOT})
endif()

if(NOT DEFINED CI)
  set(CI $ENV{CI})
endif()

function(ctest_once_only)

# check if CTest already running, don't start if so
if(WIN32)
  find_program(tasklist NAMES tasklist REQUIRED)
  execute_process(COMMAND ${tasklist} /fi "Imagename eq ctest.exe" /fo csv
  TIMEOUT 10
  RESULT_VARIABLE ret
  OUTPUT_VARIABLE out
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(NOT ret EQUAL 0)
    message(FATAL_ERROR "Could not check if CTest already running")
  endif()
  string(REGEX MATCHALL "(ctest.exe)" mat "${out}")
  list(LENGTH mat L)
  if(NOT L EQUAL 1)
    message(FATAL_ERROR "CTest already running ${L} times, not starting again.
    ${mat}")
  endif()
else()
  find_program(pgrep NAMES pgrep REQUIRED)
  execute_process(COMMAND ${pgrep} ctest
  TIMEOUT 10
  RESULT_VARIABLE ret
  OUTPUT_VARIABLE out
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(ret EQUAL 1)
    message(VERBOSE "No CTest found running, proceeding.")
    return()
  elseif(NOT ret EQUAL 0)
    message(FATAL_ERROR "Could not check if CTest already running")
  endif()
  string(REGEX MATCHALL "([0-9]+)" mat "${out}")
  list(LENGTH mat L)
  if(NOT L EQUAL 1)
    message(FATAL_ERROR "CTest already running ${L} times, not starting again.
    ${mat}")
  endif()
endif()

endfunction(ctest_once_only)

# --- main script

ctest_once_only()

# needed CDash params
set(CTEST_NIGHTLY_START_TIME "01:00:00 UTC")
set(CTEST_SUBMIT_URL "https://my.cdash.org/submit.php?project=${CTEST_PROJECT_NAME}")

# --- Experimental, Nightly, Continuous
# https://cmake.org/cmake/help/latest/manual/ctest.1.html#dashboard-client-modes

if(NOT CTEST_MODEL)
  set(CTEST_MODEL "Experimental")
endif()

# --- other defaults
set(CTEST_TEST_TIMEOUT 10)

set(CTEST_USE_LAUNCHERS 1)
set(CTEST_OUTPUT_ON_FAILURE true)

set(CTEST_SOURCE_DIRECTORY ${CTEST_SCRIPT_DIRECTORY})
if(NOT DEFINED CTEST_BINARY_DIRECTORY)
  set(CTEST_BINARY_DIRECTORY ${CTEST_SOURCE_DIRECTORY}/build)
endif()

if(EXISTS ${CTEST_BINARY_DIRECTORY}/CMakeCache.txt)
  ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
endif()

if(NOT DEFINED CTEST_SITE AND DEFINED ENV{CTEST_SITE})
  set(CTEST_SITE $ENV{CTEST_SITE})
endif()

find_program(GIT_EXECUTABLE NAMES git REQUIRED)

# --- CTEST_BUILD_NAME is used by ctest_submit(); must be set before ctest_start()

if(NOT DEFINED CTEST_BUILD_NAME)
  # a priori we are going to use the latest Git commit
  execute_process(
  COMMAND ${GIT_EXECUTABLE} ls-remote --exit-code ${gemini3d_url} ${gemini3d_tag}
  OUTPUT_VARIABLE raw OUTPUT_STRIP_TRAILING_WHITESPACE
  TIMEOUT 15
  COMMAND_ERROR_IS_FATAL ANY
  )
  string(REGEX MATCH "([a-f]|[0-9])+" gemini_git_version ${raw})
  string(SUBSTRING ${gemini_git_version} 0 7 gemini_git_version)
  set(CTEST_BUILD_NAME ${gemini3d_tag}-${gemini_git_version})

  if(cpp)
    string(APPEND CTEST_BUILD_NAME "-cpp")
  else()
    string(APPEND CTEST_BUILD_NAME "-fortran")
  endif()
endif()

# --- find generator
function(find_generator)

if(CTEST_CMAKE_GENERATOR)
  return()
elseif(DEFINED ENV{CMAKE_GENERATOR})
  set(CTEST_CMAKE_GENERATOR $ENV{CMAKE_GENERATOR} PARENT_SCOPE)
  return()
endif()

find_program(ninja NAMES ninja ninja-build samu)

if(ninja)
  execute_process(COMMAND ${ninja} --version
  OUTPUT_VARIABLE ninja_version OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE ret
  TIMEOUT 5
  )
  if(ret EQUAL 0 AND ninja_version VERSION_GREATER_EQUAL 1.10)
    set(CTEST_CMAKE_GENERATOR Ninja PARENT_SCOPE)
    return()
  endif()
endif(ninja)

set(CTEST_BUILD_FLAGS -j)  # not --parallel as this goes to generator directly
if(WIN32)
  set(CTEST_CMAKE_GENERATOR "MinGW Makefiles" PARENT_SCOPE)
else()
  set(CTEST_CMAKE_GENERATOR "Unix Makefiles" PARENT_SCOPE)
endif()

endfunction(find_generator)

find_generator()

# --- CTest Dashboard

set(CTEST_SUBMIT_RETRY_COUNT 2)
# avoid auto-detect version control failures on some systems
set(CTEST_UPDATE_TYPE git)
set(CTEST_UPDATE_COMMAND git)

ctest_start(${CTEST_MODEL})

if(CTEST_MODEL MATCHES "(Nightly|Continuous)")
  # this erases local code changes i.e. anything not "git push" already is lost forever!
  # we try to avoid that by guarding with a Git porcelain check
  execute_process(COMMAND ${GIT_EXECUTABLE} status --porcelain
  WORKING_DIRECTORY ${CTEST_SOURCE_DIRECTORY}
  TIMEOUT 5
  OUTPUT_VARIABLE ret OUTPUT_STRIP_TRAILING_WHITESPACE
  COMMAND_ERROR_IS_FATAL ANY
  )
  if(ret AND NOT "${CI}")
    message(FATAL_ERROR "CTest would have erased the non-Git Push'd changes.")
  else()
    ctest_update(
    RETURN_VALUE stat
    CAPTURE_CMAKE_ERROR err
    )
    if(stat LESS 0 OR NOT err EQUAL 0)
      message(FATAL_ERROR "Update failed: return ${ret} cmake return ${err}")
    endif()
  endif()

  # Now check Gemini3D ExternalProject directory for changes, it autoupdates as part of CMake script ExternalProject
  # since UPDATE_DISCONNECTED is false.
  cmake_path(SET gemini3d_ep ${CTEST_BINARY_DIRECTORY}/GEMINI3D_RELEASE-prefix/src/GEMINI3D_RELEASE/)
  if(CTEST_MODEL STREQUAL Continuous AND IS_DIRECTORY ${gemini3d_ep})

    execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
    WORKING_DIRECTORY ${gemini3d_ep}
    TIMEOUT 5
    OUTPUT_VARIABLE out OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE ret
    COMMAND_ERROR_IS_FATAL ANY
    )

    if(stat EQUAL 0 AND ret EQUAL 0 AND out STREQUAL ${gemini_git_version})
      message(NOTICE "No Git-updated files -> no need to test in CTest Model ${CTEST_MODEL}. CTest stopping.")
      return()
    endif()

  endif()
endif()

# --- configure

ctest_configure(
OPTIONS "${opts}"
RETURN_VALUE ret
CAPTURE_CMAKE_ERROR err
)
if(submit AND NOT (ret EQUAL 0 AND err EQUAL 0))
  ctest_submit(BUILD_ID build_id)
  message(FATAL_ERROR "Configure ${build_id} failed: return ${ret} cmake return ${err}")
endif()

ctest_build(
RETURN_VALUE ret
CAPTURE_CMAKE_ERROR err
)
if(submit)
  ctest_submit(
  BUILD_ID build_id
  PARTS Start Update Configure Build
  )
endif()
if(NOT (ret EQUAL 0 AND err EQUAL 0))
  message(FATAL_ERROR "Build ${build_id} failed: return ${ret} cmake return ${err}")
endif()

ctest_test(
SCHEDULE_RANDOM true
EXCLUDE ${exclude}
INCLUDE ${include}
EXCLUDE_LABEL ${exclude_label}
INCLUDE_LABEL ${include_label}
RETURN_VALUE ret
CAPTURE_CMAKE_ERROR err
)
# OUTPUT_JUNIT ${CTEST_BINARY_DIRECTORY}/junit_${build_id}.xml # cmake 3.21

if(submit)
  ctest_submit(
  BUILD_ID build_id
  PARTS Test Done
  )
endif()
if(NOT (ret EQUAL 0 AND err EQUAL 0))
  message(FATAL_ERROR "Test ${build_id} failed: CTest code ${ret}, CMake code ${err}.")
endif()

message(STATUS "OK: CTest build ${build_id}")
