find_package(Matlab COMPONENTS MAIN_PROGRAM REQUIRED)
if(Matlab_VERSION_STRING VERSION_LESS 9.9)
  message(STATUS "Matlab >= 9.9 required, found Matlab ${Matlab_VERSION_STRING}")
endif()

find_path(matgemini_SOURCE_DIR
NAMES setup.m
PATHS ${PROJECT_SOURCE_DIR}/../mat_gemini/
HINTS ${MATGEMINI_ROOT} ENV MATGEMINI ENV MATGEMINI_ROOT
REQUIRED
)

find_path(stdlib_SOURCE_DIR
NAMES +stdlib
HINTS ${matgemini_SOURCE_DIR}/matlab-stdlib
NO_DEFAULT_PATH
REQUIRED
)

set(MATLABPATH ${matgemini_SOURCE_DIR} ${stdlib_SOURCE_DIR})

if(MATGEMINI_FOUND)
  return()
endif()

execute_process(COMMAND ${Matlab_MAIN_PROGRAM} -batch "run('${matgemini_SOURCE_DIR}/setup.m'), stdlib.fileio.expanduser('~');"
TIMEOUT 90
RESULT_VARIABLE ret
ERROR_VARIABLE err
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "MatGemini not available:
  ${ret}
  ${err}"
  )
endif()

set(MATGEMINI_FOUND true CACHE BOOL "MatGemini found")
