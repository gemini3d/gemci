# This project assumes an "installed" Gemini3D that is a particular
# version and/or Git tag that we wish to use as a milestone.

# We use a lot of recent CMake features for CI.
cmake_minimum_required(VERSION 3.20...${CMAKE_VERSION})

project(GeminiCI
LANGUAGES NONE
HOMEPAGE_URL https://github.com/gemini3d/gemini-examples
DESCRIPTION "Long-running Gemini3D test cases"
VERSION 0.1.0)

include(CTest)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/Modules)

include(cmake/options.cmake)
include(cmake/libraries.cmake)

include(cmake/get_simroot.cmake)
message(STATUS "simulation root directory ${GEMINI_SIMROOT}")

include(cmake/ParseNml.cmake)

find_package(Gemini3D REQUIRED)

find_program(MPIEXEC_EXECUTABLE
  NAMES mpiexec
  HINTS MPI_ROOT ENV MPI_ROOT
  PATH_SUFFIXES bin
  REQUIRED)

# helper functions
include(cmake/GetEquil.cmake)
include(cmake/InputSetup.cmake)
include(cmake/ModelSetup.cmake)
include(cmake/GeminiRun.cmake)
include(cmake/GeminiCompare.cmake)
include(cmake/GeminiPlot.cmake)
include(cmake/GeminiPackage.cmake)

set(ci_root ${CMAKE_CURRENT_SOURCE_DIR}/cfg)



# --- PyGemini
if(python)
  include(cmake/python.cmake)
endif()

# --- MatGemini
if(matlab)
  include(cmake/matlab.cmake)
endif()
include(cmake/MatlabTest.cmake)

# --- discover tests

if(equil)
  file(GLOB equilibrium_dirs LIST_DIRECTORIES true "${ci_root}/equilibrium/*")
endif()
file(GLOB hourly_dirs LIST_DIRECTORIES true "${ci_root}/hourly/*")
file(GLOB daily_dirs LIST_DIRECTORIES true "${ci_root}/daily/*")

# --- init package directory and ref json
if(package)
  string(TIMESTAMP package_date "%Y-%m-%d" UTC)
  cmake_path(APPEND upload_root ${GEMINI_SIMROOT} upload-${package_date})
  set(ref_json_file ${upload_root}/ref.json)
  message(STATUS "packaging archives in ${upload_root}")

  file(MAKE_DIRECTORY ${upload_root})
  if(NOT EXISTS ${ref_json_file})
    # we will read this file and overwrite with new JSON for each sim
    file(WRITE ${ref_json_file} "{}")
  endif()
endif()


# --- main loop

foreach(in_dir ${equilibrium_dirs} ${hourly_dirs} ${daily_dirs})


cmake_path(GET in_dir PARENT_PATH _t)
cmake_path(GET _t STEM type_label)
cmake_path(GET in_dir FILENAME name)

message(DEBUG "${name}: ${type_label}")

cmake_path(APPEND out_dir ${GEMINI_SIMROOT} ${name})

# input data download (if not an equilibrium itself)
if(NOT type_label STREQUAL equilibrium)
  input_setup(${in_dir} ${out_dir} ${name} ${type_label} ${equil})
endif()

# setup model
model_setup(${in_dir} ${out_dir} ${name} ${type_label} ${equil})

# --- compare sim input
compare_download(${out_dir} ${ref_root} ${name} ${type_label})
compare_input(${GEMINI_COMPARE} ${out_dir} ${ref_root} ${name} ${type_label})

# check that scripts can read grid
if(py_ok)
  add_test(NAME "read_grid:python:${name}"
    COMMAND ${Python_EXECUTABLE} -c "import gemini3d.read; xg = gemini3d.read.grid('${out_dir}'); print(xg['lx'])")
  set_tests_properties("read_grid:python:${name}" PROPERTIES
    REQUIRED_FILES ${out_dir}/inputs/simgrid.h5
    FIXTURES_REQUIRED ${name}:setup_fxt
    LABELS python
    TIMEOUT 30)
endif()

# --- run
gemini_run(${GEMINI_RUN} ${out_dir} ${name} ${type_label})

# --- compare sim output
compare_output(${GEMINI_COMPARE} ${out_dir} ${ref_root} ${name} ${type_label})

# --- plot
gemini_plot(${out_dir} ${name} ${type_label})

# --- package upload
if(package)
  gemini_package(${GEMINI_SIMROOT} ${out_dir} ${ref_json_file} ${name} ${type_label})
endif()

endforeach()

# ---
include(FeatureSummary)

add_feature_info(compare compare "compare gemini3d output")
add_feature_info(PyGemini py_ok "PyGemini setup and plot")
add_feature_info(MatGemini MATGEMINI_DIR "MatGemini setup and plot")

feature_summary(WHAT ENABLED_FEATURES)