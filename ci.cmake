cmake_minimum_required(VERSION 3.21...3.25)

set(CTEST_PROJECT_NAME "GemCI")

set(CTEST_LABELS_FOR_SUBPROJECTS "python;matlab")

set(gemini3d_url https://github.com/gemini3d/gemini3d.git)

option(cpp "use C++ Gemini3D frontend")
option(submit "use CDash upload" true)

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

if(NOT gemini3d_tag)
  set(gemini3d_tag "main")
endif()

set(opts
-Dcpp:BOOL=${cpp}
-Ddev:BOOL=no
-Dmatlab:BOOL=no
-Dpython:BOOL=yes
-Dgemini3d_tag=${gemini3d_tag}
)

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

if(NOT duration)
  set(duration 43200)
endif()
# how long Continuous model runs before exiting for the day.
# say Cron starts Continous at 9AM local time, 43200 seconds is 12 hours.
# This allows Nightly to run after 9PM local time.
if(NOT cadence)
  set(cadence 600)
endif()

find_program(GIT_EXECUTABLE NAMES git REQUIRED)


function(get_remote url tag ovar)

execute_process(
COMMAND ${GIT_EXECUTABLE} ls-remote --exit-code ${url} ${tag}
OUTPUT_VARIABLE raw OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Could not check Git remote status ${url} ${tag}")
endif()
string(REGEX MATCH "([a-f]|[0-9])+" git_version ${raw})
string(SUBSTRING ${git_version} 0 7 git_version)

set(${ovar} ${git_version} PARENT_SCOPE)

endfunction(get_remote)


function(compare_remote ovar)

get_remote(${gemini3d_url} ${gemini3d_tag} gemini_git_version)

execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
WORKING_DIRECTORY ${gemini3d_ep}
OUTPUT_VARIABLE out OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Could not get Git commit hash for ${gemini3d_ep}")
endif()

if(out STREQUAL "${gemini_git_version}")
  set(${ovar} false PARENT_SCOPE)
else()
  set(${ovar} true PARENT_SCOPE)
endif()

endfunction(compare_remote)


function(windows_find_task exe ovar)

find_program(tasklist NAMES tasklist REQUIRED)

execute_process(COMMAND ${tasklist} /fi "Imagename eq ${exe}" /fo csv
RESULT_VARIABLE ret
OUTPUT_VARIABLE out
OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Could not check if CTest already running")
endif()

string(REGEX MATCHALL "(${exe})" mat "${out}")
list(LENGTH mat L)
if(L EQUAL 1)
  set(${ovar} false PARENT_SCOPE)
else()
  set(${ovar} true PARENT_SCOPE)
endif()

endfunction(windows_find_task)


function(unix_find_task exe ovar)

find_program(pgrep NAMES pgrep REQUIRED)

execute_process(COMMAND ${pgrep} ${exe}
RESULT_VARIABLE ret
OUTPUT_VARIABLE out
OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(ret EQUAL 1)
  set(${ovar} false PARENT_SCOPE)
  return()
elseif(NOT ret EQUAL 0)
  message(FATAL_ERROR "Could not check if CTest already running")
endif()

string(REGEX MATCHALL "([0-9]+)" mat "${out}")
list(LENGTH mat L)
if(L EQUAL 1)
  set(${ovar} false PARENT_SCOPE)
else()
  set(${ovar} true PARENT_SCOPE)
endif()

endfunction(unix_find_task)


function(ctest_once_only)
# check if CTest already running, sleep for a time if so.

set(max_wait 3600)

while(${CTEST_ELAPSED_TIME} LESS ${max_wait})

  if(WIN32)
    windows_find_task("ctest.exe" ctest_running)
  else()
    unix_find_task("ctest" ctest_running)
  endif()

  if(ctest_running)
    message(STATUS "CTest already running.  Sleeping for ${cadence} seconds to try again.")
    ctest_sleep(${cadence})
  else()
    return()
  endif()

endwhile()

message(FATAL_ERROR "Another CTest was running for ${max_wait} seconds.  Aborting.")

endfunction(ctest_once_only)


function(safe_update ovar)

# this erases local code changes i.e. anything not "git push" already is lost forever!
# avoid that by guarding with a Git porcelain check
execute_process(COMMAND ${GIT_EXECUTABLE} status --porcelain
WORKING_DIRECTORY ${CTEST_SOURCE_DIRECTORY}
OUTPUT_VARIABLE out OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Could not check if Git ${CTEST_SOURCE_DIRECTORY} is clean")
elseif(out AND NOT "${CI}")
  message(FATAL_ERROR "CTest would have erased the non-Git Push'd changes in ${CTEST_SOURCE_DIRECTORY}")
endif()

ctest_update(
RETURN_VALUE stat
CAPTURE_CMAKE_ERROR err
)
if(stat LESS 0 OR NOT err EQUAL 0)
  message(FATAL_ERROR "Update failed ${CTEST_SOURCE_DIRECTORY}: return ${stat} cmake return ${err}")
endif()

set(${ovar} ${stat} PARENT_SCOPE)

endfunction(safe_update)


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
  )
  if(ret EQUAL 0 AND ninja_version VERSION_GREATER_EQUAL 1.10)
    set(CTEST_CMAKE_GENERATOR Ninja PARENT_SCOPE)
    return()
  endif()
endif(ninja)

set(CTEST_BUILD_FLAGS -j PARENT_SCOPE)
# not --parallel as this goes to generator directly
if(WIN32)
  set(CTEST_CMAKE_GENERATOR "MinGW Makefiles" PARENT_SCOPE)
else()
  set(CTEST_CMAKE_GENERATOR "Unix Makefiles" PARENT_SCOPE)
endif()

endfunction(find_generator)




function(main)

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
EXCLUDE "${exclude}"
INCLUDE "${include}"
EXCLUDE_LABEL "${exclude_label}"
INCLUDE_LABEL "${include_label}"
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

endfunction(main)


# --- main script

ctest_once_only()

# needed CDash params

set(CTEST_NIGHTLY_START_TIME "04:00:00 UTC")
set(CTEST_SUBMIT_URL "https://my.cdash.org/submit.php?project=${CTEST_PROJECT_NAME}")

# --- Experimental, Nightly, Continuous
# https://cmake.org/cmake/help/latest/manual/ctest.1.html#dashboard-client-modes

if(NOT CTEST_MODEL)
  set(CTEST_MODEL "Experimental")
endif()

# --- other defaults
if(NOT CTEST_TEST_TIMEOUT)
  set(CTEST_TEST_TIMEOUT 1800)
endif()

set(CTEST_USE_LAUNCHERS true)
set(CTEST_OUTPUT_ON_FAILURE true)
set(CTEST_START_WITH_EMPTY_BINARY_DIRECTORY_ONCE true)

set(CTEST_SOURCE_DIRECTORY ${CTEST_SCRIPT_DIRECTORY})
if(NOT DEFINED CTEST_BINARY_DIRECTORY)
  set(CTEST_BINARY_DIRECTORY ${CTEST_SOURCE_DIRECTORY}/build)
endif()

if(NOT DEFINED CTEST_SITE AND DEFINED ENV{CTEST_SITE})
  set(CTEST_SITE $ENV{CTEST_SITE})
endif()

# --- CTEST_BUILD_NAME is used by ctest_submit(); must be set before ctest_start()

get_remote(${gemini3d_url} ${gemini3d_tag} gemini_git_version)

if(NOT DEFINED CTEST_BUILD_NAME)
  set(CTEST_BUILD_NAME ${gemini3d_tag}-${gemini_git_version})

  if(cpp)
    string(APPEND CTEST_BUILD_NAME "-cpp")
  else()
    string(APPEND CTEST_BUILD_NAME "-fortran")
  endif()
endif()

find_generator()

# --- CTest Dashboard

set(CTEST_SUBMIT_RETRY_COUNT 2)
# avoid auto-detect version control failures on some systems
set(CTEST_UPDATE_TYPE git)
set(CTEST_UPDATE_COMMAND git)

ctest_start(${CTEST_MODEL})

if(CTEST_MODEL STREQUAL "Nightly")
  safe_update(stat)
  main()
elseif(CTEST_MODEL STREQUAL "Continuous")
  # Check Gemini3D ExternalProject directory for changes, it autoupdates as part of CMake script ExternalProject
  # since UPDATE_DISCONNECTED is false.

  set(gemini3d_ep ${CTEST_BINARY_DIRECTORY}/GEMINI3D_RELEASE-prefix/src/GEMINI3D_RELEASE/)

  while(${CTEST_ELAPSED_TIME} LESS ${duration})
    set(t0 ${CTEST_ELAPSED_TIME})

    safe_update(stat)

    if(stat EQUAL 0)
      compare_remote(${gemini3d_url} ${gemini3d_tag} need_run)
    else()
      set(need_run true)
    endif()

    if(need_run)
      main()
    else()
      message(STATUS "No changes to ${gemini3d_ep} since last build; sleeping for ${cadence} seconds")
    endif()

    # ensure the loop period will be at least cadence seconds
    ctest_sleep(${t0} ${cadence} ${CTEST_ELAPSED_TIME})
  endwhile()

  message(STATUS "Continuous build duration ${duration} fulfilled, exiting")
else()
  main()
endif()
