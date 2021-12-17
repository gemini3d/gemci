option(python "use Python for tests" on)
option(matlab "use Matlab (slower than Python)")

option(dev "dev mode" on)

option(equil "run equilibrium (takes 10+ hours)")
option(package "package reference data .zst files")

cmake_host_system_information(RESULT host_ramMB QUERY TOTAL_PHYSICAL_MEMORY)
cmake_host_system_information(RESULT host_cpu QUERY PROCESSOR_DESCRIPTION)

set(CMAKE_TLS_VERIFY true)

if(NOT DEFINED low_ram)
  set(low_ram false)
  if(host_ramMB LESS 18000)
    # 18 GB: the 3D Matlab plots use 9GB RAM each
    set(low_ram true)
  endif()
endif()

if(EXISTS ${PROJECT_SOURCE_DIR}/../mat_gemini/setup.m)
  set(FETCHCONTENT_SOURCE_DIR_MATGEMINI ${PROJECT_SOURCE_DIR}/../mat_gemini CACHE PATH "MatGemini developer path")
endif()

set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED false)

if(dev)

else()
  set(FETCHCONTENT_UPDATES_DISCONNECTED_MATGEMINI true)
endif()

# --- for ExternalProject generator
if(CMAKE_GENERATOR STREQUAL "Ninja Multi-Config")
  set(EXTPROJ_GENERATOR "Ninja")
else()
  set(EXTPROJ_GENERATOR ${CMAKE_GENERATOR})
endif()

# --- default install directory
# users can specify like "cmake -B build -DCMAKE_INSTALL_PREFIX=~/mydir"
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  # will not take effect without FORCE
  set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "Install top-level directory" FORCE)
endif()

# --- auto-ignore build directory
if(NOT EXISTS ${PROJECT_BINARY_DIR}/.gitignore)
  file(WRITE ${PROJECT_BINARY_DIR}/.gitignore "*")
endif()
