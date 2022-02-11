find_package(Python 3.8...4 COMPONENTS Interpreter REQUIRED)

if(PYGEMINI_VERSION)
  return()
endif()

execute_process(COMMAND ${Python_EXECUTABLE} -c "import gemini3d.model"
RESULT_VARIABLE ret
ERROR_VARIABLE err
TIMEOUT 15
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "PyGemini not functioning or found:
  ${ret}
  ${err}"
  )
endif()

execute_process(COMMAND ${Python_EXECUTABLE} -c "import gemini3d; print(gemini3d.__version__)"
RESULT_VARIABLE ret
OUTPUT_VARIABLE out
ERROR_VARIABLE err
TIMEOUT 15
OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to get PyGemini version:
  ${ret}
  ${out}
  ${err}"
  )
endif()

set(PYGEMINI_VERSION ${out} CACHE STRING "PyGemini version")
