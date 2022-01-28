option(python "use Python for tests" on)
option(matlab "use Matlab (slower than Python)")

option(dev "dev mode" on)

option(equil "run equilibrium (takes 10+ hours)")
option(package "package reference data .zst files")
option(python "Use python" on)
option(matlab "Use matlab")

set(CMAKE_TLS_VERIFY true)


if(EXISTS ${PROJECT_SOURCE_DIR}/../mat_gemini/setup.m)
  set(FETCHCONTENT_SOURCE_DIR_MATGEMINI ${PROJECT_SOURCE_DIR}/../mat_gemini CACHE PATH "MatGemini developer path")
endif()


if(dev)
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED true)
else()
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED false)
  set(FETCHCONTENT_UPDATES_DISCONNECTED_MATGEMINI true)
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
