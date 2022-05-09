if(EXISTS ${ref_json_file})
  file(READ ${ref_json_file} ref_json)
else()
  cmake_path(GET ref_json_file PARENT_PATH _p)
  file(MAKE_DIRECTORY ${_p})
  set(ref_json "{}")
endif()

# check if tag exists, create new file if not (must be bad JSON file)
string(JSON m ERROR_VARIABLE e GET ${ref_json} system)
if(NOT m)
  string(JSON ref_json SET "{}" system "{}")
endif()

string(JSON ref_json SET ${ref_json} system cmake_version \"${CMAKE_VERSION}\")

# CMAKE_BUILD_TYPE, CMAKE_*_COMPILER_ID not relevant for GemCI itself

string(JSON ref_json SET ${ref_json} system operating_system \"${CMAKE_HOST_SYSTEM_NAME}\")
string(JSON ref_json SET ${ref_json} system cpu \"${host_cpu}\")
string(JSON ref_json SET ${ref_json} system memory_ram_MB ${host_ramMB})
set(c "${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
string(JSON ref_json SET ${ref_json} system c_compiler \"${c}\")
set(c "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
string(JSON ref_json SET ${ref_json} system cpp_compiler \"${c}\")
set(c "${CMAKE_Fortran_COMPILER_ID} ${CMAKE_Fortran_COMPILER_VERSION}")
string(JSON ref_json SET ${ref_json} system fortran_compiler \"${c}\")

# write meta data to file
file(WRITE ${ref_json_file} ${ref_json})
