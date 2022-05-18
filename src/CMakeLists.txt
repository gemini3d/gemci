# ensure needed libraries are available

find_program(MPIEXEC_EXECUTABLE
NAMES mpiexec
HINTS ${MPI_ROOT} ENV MPI_ROOT ENV I_MPI_ROOT
PATHS /usr/lib64 ENV MINGWROOT ENV MSMPI_BIN
PATH_SUFFIXES bin openmpi/bin mpich/bin
DOC "Runs an MPI program"
REQUIRED
)

# --- helper functions
include(${PROJECT_SOURCE_DIR}/cmake/ParseNml.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/GetEquil.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/InputSetup.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/ModelSetup.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/GeminiRun.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/GeminiCompare.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/GeminiPlot.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/GeminiPackage.cmake)

# --- top level directories
cmake_path(SET ci_root ${PROJECT_SOURCE_DIR}/cfg)
cmake_path(SET ref_root ${GEMINI_CIROOT}/test_ref)

file(MAKE_DIRECTORY ${ref_root})

# --- measure system physical RAM
cmake_host_system_information(RESULT host_ramMB QUERY TOTAL_PHYSICAL_MEMORY)

if(NOT DEFINED low_ram)
  set(low_ram false)
  if(host_ramMB LESS 18000)
    # 18 GB: the 3D Matlab plots use 9GB RAM each
    set(low_ram true)
  endif()
endif()

# --- PyGemini
if(python)
  include(${PROJECT_SOURCE_DIR}/cmake/python.cmake)
endif()

# --- MatGemini
if(matlab)
  include(${PROJECT_SOURCE_DIR}/cmake/matlab.cmake)
endif()
include(${PROJECT_SOURCE_DIR}/cmake/MatlabTest.cmake)

# --- download reference data JSON file (for previously generated data)
cmake_path(SET arc_json_file ${PROJECT_BINARY_DIR}/ref_data.json)
if(NOT EXISTS ${arc_json_file})
  file(READ ${PROJECT_SOURCE_DIR}/cmake/libraries.json _libj)
  string(JSON url GET ${_libj} ref_data url)
  file(DOWNLOAD ${url} ${arc_json_file}
  INACTIVITY_TIMEOUT 15
  STATUS ret
  )
  list(GET ret 0 stat)
  if(NOT stat EQUAL 0)
    list(GET ret 1 err)
    message(FATAL_ERROR "${url} download failed: ${err}")
  endif()
endif()

# --- discover tests

if(equil)
  file(GLOB equilibrium_dirs LIST_DIRECTORIES true "${ci_root}/equilibrium/*")
endif()
file(GLOB hourly_dirs LIST_DIRECTORIES true "${ci_root}/hourly/*")
file(GLOB daily_dirs LIST_DIRECTORIES true "${ci_root}/daily/*")

# --- init package directory and ref json
if(package)
  string(TIMESTAMP package_date "%Y-%m-%d" UTC)
  cmake_path(SET upload_root ${GEMINI_CIROOT}/upload-${package_date})
  cmake_path(SET ref_json_file ${upload_root}/ref_data.json)

  include(${PROJECT_SOURCE_DIR}/cmake/system_meta.cmake)

  message(STATUS "packaging archives in ${upload_root}")
endif()

# --- check if Internet connectivity at ctest time
add_test(NAME internetConnectivity
COMMAND ${CMAKE_COMMAND} -P ${PROJECT_SOURCE_DIR}/cmake/connectivity.cmake)
set_tests_properties(internetConnectivity PROPERTIES
TIMEOUT 3
FIXTURES_SETUP internet_fxt
)

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

set(${name}_DISABLED 0)

if(NOT name MATCHES "_eq$")
  if(msis2 AND NOT name MATCHES "msis2")
    message(STATUS "MSIS2 requested, skipping ${name}")
    continue()
  endif()

  if(hwm14 AND NOT name MATCHES "hwm14")
    message(STATUS "HWM14 requested, skipping ${name}")
    continue()
  endif()
endif()

# --- proceed with simulation setup
cmake_path(SET out_dir ${GEMINI_CIROOT}/${name})

# input data download (if not an equilibrium itself)
if(NOT type_label STREQUAL equilibrium)
  input_setup(${in_dir} ${out_dir} ${name} ${type_label} ${equil})
endif()

# setup model
model_setup(${in_dir} ${out_dir} ${ref_root} ${name} ${type_label} ${low_ram})

# --- compare sim input
compare_download(${out_dir} ${ref_root} ${name} ${type_label})
if(python OR matlab)
  compare_input(${GEMINI_COMPARE} ${out_dir} ${ref_root} ${name} ${type_label})
endif()

# check that scripts can read grid
if(python)
  add_test(NAME "read_grid:python:${name}"
  COMMAND ${Python_EXECUTABLE} -c "import gemini3d.read; xg = gemini3d.read.grid('${out_dir}'); print(xg['lx'])"
  )
  set_tests_properties("read_grid:python:${name}" PROPERTIES
  REQUIRED_FILES ${out_dir}/inputs/simgrid.h5
  FIXTURES_REQUIRED ${name}:setup_fxt
  LABELS python
  DISABLED ${${name}_DISABLED}
  TIMEOUT 30
  )
endif(python)

# --- run
gemini_run(${out_dir} ${name} ${type_label})

# --- compare sim output
compare_output(${GEMINI_COMPARE} ${out_dir} ${ref_root} ${name} ${type_label})

# --- plot
if(plot)
  gemini_plot(${out_dir} ${name} ${type_label})
endif()

# --- package upload
if(package)
  gemini_package(${GEMINI_CIROOT} ${out_dir} ${ref_json_file} ${name} ${type_label})
endif()

endforeach()

# ---
include(FeatureSummary)

add_feature_info(compare compare "compare gemini3d output")
add_feature_info(PyGemini python "PyGemini setup and plot")
add_feature_info(MatGemini matlab "MatGemini setup and plot")
add_feature_info(plotting plot "plotting of in/out and compare diffs")

feature_summary(WHAT ENABLED_FEATURES)
