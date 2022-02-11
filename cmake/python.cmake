find_package(Python 3.8...4 COMPONENTS Interpreter REQUIRED)

if(py_ok)
  return()
endif()

execute_process(COMMAND ${Python_EXECUTABLE} -c "import gemini3d.model"
RESULT_VARIABLE ret
TIMEOUT 15
)

if(ret EQUAL 0)
  set(py_ok true CACHE BOOL "PyGemini detected.")
else()
  message(WARNING "PyGemini not functioning or found")
  set(py_ok false)
  return()
endif()

execute_process(COMMAND ${Python_EXECUTABLE} -c "import gemini3d; print(gemini3d.__version__)"
RESULT_VARIABLE ret
OUTPUT_VARIABLE _v
TIMEOUT 15
OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(ret EQUAL 0)
  set(PYGEMINI_VERSION ${_v} CACHE STRING "PyGemini version")
else()
  message(STATUS "Failed to get PyGemini version: ${ret}   ${_v}")
endif()
