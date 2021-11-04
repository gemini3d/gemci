option(python "use Python for tests" on)
option(matlab "use Matlab (slower than Python)")

option(dev "dev mode" on)

option(equil "run equilibrium (takes 10+ hours)")
option(package "package reference data .zst files")

cmake_host_system_information(RESULT host_ramMB QUERY TOTAL_PHYSICAL_MEMORY)
cmake_host_system_information(RESULT host_cpu QUERY PROCESSOR_DESCRIPTION)

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

if(dev)

else()
  set(FETCHCONTENT_UPDATES_DISCONNECTED_MATGEMINI true)
endif()

# --- auto-ignore build directory
if(NOT EXISTS ${PROJECT_BINARY_DIR}/.gitignore)
  file(WRITE ${PROJECT_BINARY_DIR}/.gitignore "*")
endif()
