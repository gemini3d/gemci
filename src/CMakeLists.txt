file(MAKE_DIRECTORY ${ref_root})

# --- download reference data JSON file (for previously generated data)
cmake_path(SET arc_json_file ${PROJECT_BINARY_DIR}/ref_data.json)
if(NOT EXISTS ${arc_json_file})
  file(READ ${PROJECT_SOURCE_DIR}/cmake/libraries.json _libj)
  string(JSON url GET ${_libj} ref_data url)
  file(DOWNLOAD ${url} ${arc_json_file}
  INACTIVITY_TIMEOUT 60
  STATUS ret
  LOG log
  )
  list(GET ret 0 stat)
  if(NOT stat EQUAL 0)
    list(GET ret 1 err)
    message(FATAL_ERROR "${url} download failed: ${err}
    ${log}")
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
# add_test(NAME internetConnect
# COMMAND ${CMAKE_COMMAND} -P ${PROJECT_SOURCE_DIR}/cmake/connectivity.cmake)
# set_property(TEST internetConnect PROPERTY FIXTURES_SETUP internet_fxt)
# set_property(TEST internetConnect PROPERTY DISABLED true)

# --- main loop

foreach(in_dir IN LISTS equilibrium_dirs hourly_dirs daily_dirs)

if(NOT IS_DIRECTORY ${in_dir})
  message(VERBOSE "${in_dir} is not a directory, thus not a simulation")
  continue()  # stray file
elseif(NOT EXISTS ${in_dir}/config.nml)
  message(STATUS "${in_dir} does not contain config.nml")
  continue()
endif()

cmake_path(GET in_dir PARENT_PATH _t)
cmake_path(GET _t STEM type_label)
cmake_path(GET in_dir FILENAME name)

message(DEBUG "${name}: ${type_label}   from ${in_dir}")

# --- test down-selection
set(${name}_DISABLED 0)

if(name MATCHES "_eq$")
  if(msis2)
    if(NOT name MATCHES "msis2")
      message(STATUS "MSIS2 requested, skipping ${name}")
      continue()
    endif()
  else(msis2)
    if(name MATCHES "msis2")
      message(STATUS "MSIS2 not requested, skipping ${name}")
      continue()
    endif()
  endif(msis2)
else()
  if(hwm14)
    if(NOT name MATCHES "hwm14")
      message(STATUS "HWM14 requested, skipping ${name}")
      continue()
    endif()
  else(hwm14)
    if(name MATCHES "hwm14")
      message(STATUS "HWM14 not requested, skipping ${name}")
      continue()
    endif()
  endif(hwm14)
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
