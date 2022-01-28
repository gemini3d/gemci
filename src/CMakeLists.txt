cmake_minimum_required(VERSION 3.20...3.22)

project(Gemini3D_CI LANGUAGES NONE)

enable_testing()

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/../cmake/Modules)

include(${PROJECT_SOURCE_DIR}/../cmake/libraries.cmake)

include(${PROJECT_SOURCE_DIR}/../cmake/get_simroot.cmake)
message(STATUS "simulation root directory ${GEMINI_CIROOT}")

include(${PROJECT_SOURCE_DIR}/../cmake/ParseNml.cmake)

find_package(Gemini3D REQUIRED)

# helper functions
include(${PROJECT_SOURCE_DIR}/../cmake/GetEquil.cmake)
include(${PROJECT_SOURCE_DIR}/../cmake/InputSetup.cmake)
include(${PROJECT_SOURCE_DIR}/../cmake/ModelSetup.cmake)
include(${PROJECT_SOURCE_DIR}/../cmake/GeminiRun.cmake)
include(${PROJECT_SOURCE_DIR}/../cmake/GeminiCompare.cmake)
include(${PROJECT_SOURCE_DIR}/../cmake/GeminiPlot.cmake)
include(${PROJECT_SOURCE_DIR}/../cmake/GeminiPackage.cmake)

set(ci_root ${PROJECT_SOURCE_DIR}/../cfg)

# --- measure system physical RAM
cmake_host_system_information(RESULT host_ramMB QUERY TOTAL_PHYSICAL_MEMORY)
cmake_host_system_information(RESULT host_cpu QUERY PROCESSOR_DESCRIPTION)

if(NOT DEFINED low_ram)
  set(low_ram false)
  if(host_ramMB LESS 18000)
    # 18 GB: the 3D Matlab plots use 9GB RAM each
    set(low_ram true)
  endif()
endif()

# --- PyGemini
if(python)
  include(${PROJECT_SOURCE_DIR}/../cmake/python.cmake)
endif()

# --- MatGemini
if(matlab)
  include(${PROJECT_SOURCE_DIR}/../cmake/matlab.cmake)
endif()
include(${PROJECT_SOURCE_DIR}/../cmake/MatlabTest.cmake)

# --- discover tests

if(equil)
  file(GLOB equilibrium_dirs LIST_DIRECTORIES true "${ci_root}/equilibrium/*")
endif()
file(GLOB hourly_dirs LIST_DIRECTORIES true "${ci_root}/hourly/*")
file(GLOB daily_dirs LIST_DIRECTORIES true "${ci_root}/daily/*")

# --- init package directory and ref json
if(package)
  string(TIMESTAMP package_date "%Y-%m-%d" UTC)
  cmake_path(APPEND upload_root ${GEMINI_CIROOT} upload-${package_date})
  cmake_path(APPEND ref_json_file ${upload_root} ref_data.json)

  include(${PROJECT_SOURCE_DIR}/../cmake/system_meta.cmake)

  message(STATUS "packaging archives in ${upload_root}")
endif()

# --- main loop

foreach(in_dir ${equilibrium_dirs} ${hourly_dirs} ${daily_dirs})

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

# --- disable tests if Gemini3D feature not enabled
set(${name}_DISABLED 0)

if(name MATCHES "msis2" AND NOT "MSIS2" IN_LIST GEMINI_FEATURES)
  message(STATUS "MSIS2 not enabled, disabling ${name}")
  set(${name}_DISABLED 1)
endif()

if(name MATCHES "hwm14" AND NOT "HWM14" IN_LIST GEMINI_FEATURES)
  message(STATUS "HWM14 not enabled, disabling ${name}")
  set(${name}_DISABLED 1)
endif()

# message(STATUS "FEATURES: ${GEMINI_FEATURES}   ${name}: ${${name}_DISABLED}")

# --- download reference data JSON file (for previously generated data)
cmake_path(APPEND arc_json_file ${CMAKE_CURRENT_BINARY_DIR} ref_data.json)
if(NOT EXISTS ${arc_json_file})
  file(READ ${PROJECT_SOURCE_DIR}/../cmake/libraries.json _libj)
  string(JSON url GET ${_libj} ref_data url)
  file(DOWNLOAD ${url} ${arc_json_file} INACTIVITY_TIMEOUT 15)
endif()

# --- proceed with simulation setup

cmake_path(APPEND out_dir ${GEMINI_CIROOT} ${name})

# input data download (if not an equilibrium itself)
if(NOT type_label STREQUAL equilibrium)
  input_setup(${in_dir} ${out_dir} ${name} ${type_label} ${equil})
endif()

# setup model
model_setup(${in_dir} ${out_dir} ${ref_root} ${name} ${type_label} ${low_ram})

# --- compare sim input
compare_download(${out_dir} ${ref_root} ${name} ${type_label})
if(py_ok OR MATGEMINI_DIR)
  compare_input(${GEMINI_COMPARE} ${out_dir} ${ref_root} ${name} ${type_label})
endif()

# check that scripts can read grid
if(python)
  add_test(NAME "read_grid:python:${name}"
    COMMAND ${Python_EXECUTABLE} -c "import gemini3d.read; xg = gemini3d.read.grid('${out_dir}'); print(xg['lx'])")
  set_tests_properties("read_grid:python:${name}" PROPERTIES
    REQUIRED_FILES ${out_dir}/inputs/simgrid.h5
    FIXTURES_REQUIRED ${name}:setup_fxt
    LABELS python
    DISABLED $<OR:$<NOT:$<BOOL:${py_ok}>>,${${name}_DISABLED}>
    TIMEOUT 30)
endif(python)

# --- run
gemini_run(${out_dir} ${name} ${type_label})

# --- compare sim output
compare_output(${GEMINI_COMPARE} ${out_dir} ${ref_root} ${name} ${type_label})

# --- plot
gemini_plot(${out_dir} ${name} ${type_label})

# --- package upload
if(package)
  gemini_package(${GEMINI_CIROOT} ${out_dir} ${ref_json_file} ${name} ${type_label})
endif()

endforeach()

# ---
include(FeatureSummary)

add_feature_info(compare compare "compare gemini3d output")
add_feature_info(PyGemini py_ok "PyGemini setup and plot")
add_feature_info(MatGemini MATGEMINI_DIR "MatGemini setup and plot")

feature_summary(WHAT ENABLED_FEATURES)
