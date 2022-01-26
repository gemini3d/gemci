if(NOT EXISTS ${ref_json_file})
  cmake_path(GET ref_json_file PARENT_PATH _p)
  file(MAKE_DIRECTORY ${_p})
  # make a blank JSON file
  file(WRITE ${ref_json_file} "{}")
endif()

# record system metadata
file(READ ${ref_json_file} ref_json)

# check if tag exists, create if not
string(JSON m ERROR_VARIABLE e GET ${ref_json} system)
if(NOT m)
  string(JSON ref_json SET ${ref_json} system "{}")
endif()

string(JSON ref_json SET ${ref_json} system cmake_version \"${CMAKE_VERSION}\")

# CMAKE_BUILD_TYPE, CMAKE_*_COMPILER_ID not relevant for GemCI itself

string(JSON ref_json SET ${ref_json} system operating_system \"${CMAKE_HOST_SYSTEM_NAME}\")
string(JSON ref_json SET ${ref_json} system cpu \"${host_cpu}\")
string(JSON ref_json SET ${ref_json} system memory_ram_MB ${host_ramMB})
if(fortran_compiler_info)
  string(JSON ref_json SET ${ref_json} system fortran_compiler \"${fortran_compiler_info}\")
endif()

# check if tag exists, create if not
string(JSON m ERROR_VARIABLE e GET ${ref_json} gemini3d)
if(NOT m)
  string(JSON ref_json SET ${ref_json} gemini3d "{}")
endif()

if(git_branch)
  string(JSON ref_json SET ${ref_json} gemini3d git_branch \"${git_branch}\")
endif(git_branch)
if(git_porcelain)
  string(JSON ref_json SET ${ref_json} gemini3d git_porcelain ${git_porcelain})
endif(git_porcelain)

# check if tag exists, create if not
string(JSON m ERROR_VARIABLE e GET ${ref_json} library)
if(NOT m)
  string(JSON ref_json SET ${ref_json} library "{}")
endif()

foreach(n LAPACK SCALAPACK MUMPS HDF5 NetCDF MPI)
  if(${n}_LIBRARIES)
    string(REPLACE ";" "," l "${${n}_LIBRARIES}")
    string(TOLOWER ${n} nl)
    string(JSON ref_json ERROR_VARIABLE e SET ${ref_json} library ${nl} \"${l}\")
  endif()

endforeach()

file(WRITE ${ref_json_file} ${ref_json})
