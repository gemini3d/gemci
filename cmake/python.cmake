find_package(Python COMPONENTS Interpreter REQUIRED)

if(py_ok)
  return()
endif()

execute_process(COMMAND ${Python_EXECUTABLE} -c "import gemini3d.model"
COMMAND_ERROR_IS_FATAL ANY
TIMEOUT 15
)

set(py_ok true CACHE BOOL "PyGemini detected.")
