# need this here to keep modern syntax handling
cmake_minimum_required(VERSION 3.19...${CMAKE_VERSION})

function(get_equil in name)

cmake_path(APPEND nml_file ${in} config.nml)

# get equilibrium directory
parse_nml(${nml_file} "eq_dir" "path")
if(NOT eq_dir)
  message(FATAL_ERROR "${name}: missing eq_dir in ${nml_file}")
endif()

string(REGEX REPLACE "[\\/]+$" "" eq_dir "${eq_dir}") # must strip trailing slash for cmake_path(... FILENAME) to work

cmake_path(GET eq_dir FILENAME eq_name)
if(NOT eq_name)
  message(FATAL_ERROR "${name}: ${eq_dir} seems malformed, could not get directory name ${eq_name}")
endif()

# to parent
set(nml_file ${nml_file} PARENT_SCOPE)
set(eq_dir ${eq_dir} PARENT_SCOPE)
set(eq_name ${eq_name} PARENT_SCOPE)

endfunction(get_equil)
