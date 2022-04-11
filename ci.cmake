cmake_minimum_required(VERSION 3.20...3.23)

set(CTEST_PROJECT_NAME "GemCI")

set(CTEST_LABELS_FOR_SUBPROJECTS "python;matlab")

set(opts
-Ddev:BOOL=no
-Dmatlab:BOOL=no
-Dpython:BOOL=yes
)

# --- boilerplate follows

if(DEFINED ENV{CI})
  set(CI $ENV{CI})
endif()

set(CTEST_NIGHTLY_START_TIME "01:00:00 UTC")
set(CTEST_SUBMIT_URL "https://my.cdash.org/submit.php?project=${CTEST_PROJECT_NAME}")

# ctest -S doesn't have a way to pass -Dvar:type=value, so do this via env var
# list(APPEND opts $ENV{CTEST_${CTEST_PROJECT_NAME}_ARGS})

# --- Experimental, Nightly, Continuous
# https://cmake.org/cmake/help/latest/manual/ctest.1.html#dashboard-client-modes
if(NOT CTEST_MODEL AND DEFINED ENV{CTEST_MODEL})
  set(CTEST_MODEL $ENV{CTEST_MODEL})
endif()
if(NOT CTEST_MODEL AND CI)
  set(CTEST_MODEL "Nightly")
endif()
if(NOT CTEST_MODEL)
  set(CTEST_MODEL "Experimental")
endif()

# --- other defaults
set(CTEST_TEST_TIMEOUT 10)
# most of our tests take much longer than 10 seconds, but this helps ensure we don't accidentally
# let a test timeout default to ~ infinity.

set(CTEST_USE_LAUNCHERS 1)
set(CTEST_OUTPUT_ON_FAILURE true)

set(CTEST_SOURCE_DIRECTORY ${CTEST_SCRIPT_DIRECTORY})
if(NOT DEFINED CTEST_BINARY_DIRECTORY)
  set(CTEST_BINARY_DIRECTORY ${CTEST_SOURCE_DIRECTORY}/build)
endif()

if(NOT DEFINED CTEST_SITE)
  if(DEFINED ENV{CTEST_SITE})
    set(CTEST_SITE $ENV{CTEST_SITE})
  else()
    cmake_host_system_information(RESULT sys_name QUERY OS_NAME OS_RELEASE OS_VERSION)
    string(REPLACE ";" " " sys_name ${sys_name})
    set(CTEST_SITE ${sys_name})
  endif()
endif()

find_program(GIT_EXECUTABLE NAMES git REQUIRED)

if(NOT DEFINED CTEST_BUILD_NAME)
  if(DEFINED ENV{CTEST_BUILD_NAME})
    set(CTEST_BUILD_NAME $ENV{CTEST_BUILD_NAME})
  else()
    # a priori we are going to use the latest Git commit
    execute_process(COMMAND ${GIT_EXECUTABLE} ls-remote https://github.com/gemini3d/gemini3d.git main
    OUTPUT_VARIABLE raw OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE err
    TIMEOUT 15
    )

    if(err EQUAL 0)
      string(REGEX MATCH "([a-f]|[0-9])+" gemini_git_version ${raw})
      set(CTEST_BUILD_NAME ${gemini_git_version})
    endif()
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
  RESULT_VARIABLE err
  TIMEOUT 5
  )
  if(err EQUAL 0 AND ninja_version VERSION_GREATER_EQUAL 1.10)
    set(CTEST_CMAKE_GENERATOR Ninja)
  endif()
endif(ninja)

if(NOT CTEST_CMAKE_GENERATOR)
  set(CTEST_BUILD_FLAGS -j)  # not --parallel as this goes to generator directly
  if(WIN32)
    set(CTEST_CMAKE_GENERATOR "MinGW Makefiles")
  else()
    set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
  endif()
endif()

set(CTEST_CMAKE_GENERATOR ${CTEST_CMAKE_GENERATOR} PARENT_SCOPE)

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
  if(ret)
    message(FATAL_ERROR "CTest would have erased the non-Git Push'd changes, NOT updating.")
  else()
    ctest_update(
    RETURN_VALUE ret
    CAPTURE_CMAKE_ERROR err
    )
    if(ret LESS 0 OR NOT err EQUAL 0)
      message(FATAL_ERROR "Configure ${build_id} failed: return ${ret} cmake return ${err}")
    endif()
  endif()

  # Now check Gemini3D ExternalProject directory for changes, it autoupdates as part of CMake script ExternalProject
  # since UPDATE_DISCONNECTED is false.
  cmake_path(SET gemini3d_ep ${CTEST_BINARY_DIRECTORY}/GEMINI3D_RELEASE-prefix/src/GEMINI3D_RELEASE/)
  if(CTEST_MODEL STREQUAL Continuous AND IS_DIRECTORY ${gemini3d_ep})

    execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
    WORKING_DIRECTORY ${gemini3d_ep}
    TIMEOUT 5
    OUTPUT_VARIABLE ret OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE err
    )

    if(err EQUAL 0 AND ret STREQUAL ${gemini_git_version})
      message(NOTICE "No Git-updated files -> no need to test in CTest Model ${CTEST_MODEL}. CTest stopping.")
      return()
    endif()

  endif()
endif()

ctest_configure(
OPTIONS "${opts}"
RETURN_VALUE ret
CAPTURE_CMAKE_ERROR err
)
if(NOT (ret EQUAL 0 AND err EQUAL 0))
  ctest_submit(BUILD_ID build_id)
  message(FATAL_ERROR "Configure ${build_id} failed: return ${ret} cmake return ${err}")
endif()

ctest_build(
RETURN_VALUE ret
CAPTURE_CMAKE_ERROR err
)
ctest_submit(BUILD_ID build_id)
if(NOT (ret EQUAL 0 AND err EQUAL 0))
  message(FATAL_ERROR "Build ${build_id} failed: return ${ret} cmake return ${err}")
endif()

ctest_test(
BUILD ${CTEST_BINARY_DIRECTORY}/gemci
SCHEDULE_RANDOM ON
RETURN_VALUE ret
CAPTURE_CMAKE_ERROR err
)

ctest_submit(BUILD_ID build_id)

if(NOT (ret EQUAL 0 AND err EQUAL 0))
  message(FATAL_ERROR "Test ${build_id} failed: CTest code ${ret}, CMake code ${err}.")
endif()

message(STATUS "OK: CTest build ${build_id}")
