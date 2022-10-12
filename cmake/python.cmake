function(check_pygemini)

# Python::Interpreter does NOT work, use ${Python_EXECUTABLE}

# Numpy conflicts are a general source of trouble
execute_process(COMMAND ${Python_EXECUTABLE} -c "import numpy,sys; print(f'Python {sys.version}  Numpy {numpy.__version__}')"
RESULT_VARIABLE ret
OUTPUT_VARIABLE out
ERROR_VARIABLE err
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Problem with Python Numpy, cannot use PyGemini
  ${out}
  ${err}"
  )
endif()

execute_process(COMMAND ${Python_EXECUTABLE} -c "import gemini3d; print(gemini3d.__version__)"
RESULT_VARIABLE ret
OUTPUT_VARIABLE out
ERROR_VARIABLE err
OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to get PyGemini version:
  ${ret}
  ${out}
  ${err}"
  )
endif()

set(PYGEMINI_FOUND true CACHE BOOL "PyGemini Found")
set(PYGEMINI_VERSION ${out} CACHE STRING "PyGemini version")

endfunction(check_pygemini)

# --- script

find_package(Python 3.7 COMPONENTS Interpreter REQUIRED)

if(NOT PYGEMINI_FOUND)
  check_pygemini()
endif()
