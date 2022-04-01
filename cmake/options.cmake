option(python "use Python for tests" on)
option(matlab "use Matlab (slower than Python)")

option(dev "dev mode" on)

option(equil "run equilibrium (takes 10+ hours)")
option(package "package reference data .zst files")

option(plot "plot difference between reference and computed")
option(python "Use python" on)
option(matlab "Use matlab")

set(CMAKE_TLS_VERIFY true)


if(dev)
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED true)
else()
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED false)
endif()

# --- for ExternalProject generator
if(CMAKE_GENERATOR STREQUAL "Ninja Multi-Config")
  set(EXTPROJ_GENERATOR "Ninja")
else()
  set(EXTPROJ_GENERATOR ${CMAKE_GENERATOR})
endif()

# --- auto-ignore build directory
if(NOT EXISTS ${PROJECT_BINARY_DIR}/.gitignore)
  file(WRITE ${PROJECT_BINARY_DIR}/.gitignore "*")
endif()
