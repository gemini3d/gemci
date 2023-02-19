option(python "use Python for tests")
option(matlab "use Matlab (slower than Python)")
option(plot "plot difference between reference and computed")

option(hwm14 "use HWM14")
option(msis2 "use MSIS2")
option(glow "use GLOW" on)
option(cpp "test C++ Gemini3D frontend")

option(dev "dev mode")

option(equil "run equilibrium (takes 10+ hours)")
option(package "package reference data .zst files")

set(CMAKE_TLS_VERIFY true)

set(Python_FIND_REGISTRY LAST)
# this avoids non-active conda from getting picked anyway on Windows


if(dev)
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED true)
else()
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED false)
endif()

# --- auto-ignore build directory
if(NOT EXISTS ${PROJECT_BINARY_DIR}/.gitignore)
  file(WRITE ${PROJECT_BINARY_DIR}/.gitignore "*")
endif()
