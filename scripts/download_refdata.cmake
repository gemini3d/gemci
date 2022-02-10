# download all reference data
include(${CMAKE_CURRENT_LIST_DIR}/../cmake/ParseNml.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../cmake/GetEquil.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../cmake/download_input.cmake)

set(ctest_run false)

if(NOT GEMINI_CIROOT)
  message(FATAL_ERROR "Please set GEMINI_CIROOT to the desired top-level data directory. Example:
cmake -DGEMINI_CIROOT=~/gemci -P scripts/download_refdata.cmake")
endif()

cmake_path(SET ci_root NORMALIZE ${CMAKE_CURRENT_LIST_DIR}/../cfg)

# --- download reference data JSON file (for previously generated data)

cmake_path(SET arc_json_file ${CMAKE_CURRENT_BINARY_DIR}/ref_data.json)
if(NOT EXISTS ${arc_json_file})
  file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json _libj)
  string(JSON url GET ${_libj} ref_data url)
  file(DOWNLOAD ${url} ${arc_json_file} INACTIVITY_TIMEOUT 15)
endif()

# --- discover tests

file(GLOB equilibrium_dirs LIST_DIRECTORIES true "${ci_root}/equilibrium/*")
file(GLOB hourly_dirs LIST_DIRECTORIES true "${ci_root}/hourly/*")
file(GLOB daily_dirs LIST_DIRECTORIES true "${ci_root}/daily/*")

# --- main loop

foreach(in_dir IN LISTS equilibrium_dirs hourly_dirs daily_dirs)

if(NOT IS_DIRECTORY ${in_dir})
  continue()  # stray file
elseif(NOT EXISTS ${in_dir}/config.nml)
  message(STATUS "${in_dir} does not contain config.nml")
  continue()
endif()

cmake_path(GET in_dir PARENT_PATH _t)
cmake_path(GET _t STEM type_label)
cmake_path(GET in_dir FILENAME name)

message(DEBUG "${name}: ${type_label}")

cmake_path(SET out_dir ${GEMINI_CIROOT}/${name})

# --- input data download (if not an equilibrium itself)
if(NOT type_label STREQUAL equilibrium)
  get_equil(${in_dir} ${name})

  download_input(${eq_dir} ${name} tests ${arc_json_file})
endif()

# --- get neutral input directory, if specified in config.nml
parse_nml(${in_dir}/config.nml "source_dir" "path")
if(source_dir)
  download_input(${source_dir} ${name} neutrals ${arc_json_file})
endif()

endforeach()
