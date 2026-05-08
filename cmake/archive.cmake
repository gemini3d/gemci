cmake_minimum_required(VERSION 3.25)

cmake_path(GET out FILENAME archive_name)

if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.31)
  file(ARCHIVE_CREATE
  OUTPUT ${out}
  PATHS ${in}
  COMPRESSION Zstd
  COMPRESSION_LEVEL 3
  WORKING_DIRECTORY ${in}
  )
  # need WORKING_DIRECTORY ${in} to avoid computer-specific relative paths
else()
  # need WORKING_DIRECTORY ${in} to avoid computer-specific relative paths
  # use . not ${in} as last argument to avoid more relative path issues

  execute_process(
  COMMAND ${CMAKE_COMMAND} -E tar c ${out} --zstd .
  WORKING_DIRECTORY ${in}
  COMMAND_ERROR_IS_FATAL ANY
  )
endif()

# ensure a file was created (weak validation) -- errors if file doesn't exist
file(SIZE ${out} fsize)
if(fsize LESS 10000)
  message(FATAL_ERROR "Archive ${out} may be malformed.")
endif()

message(STATUS "Created archive ${out}")

# JSON update

# put hash in JSON
file(SHA256 ${out} hash)
file(READ ${ref_json_file} ref_json)
string(JSON m ERROR_VARIABLE e GET ${ref_json} tests)
if(NOT m)
  string(JSON ref_json SET ${ref_json} tests "{}")
endif()
# URL auto-populated after upload via "rclone link"
string(JSON ref_json SET ${ref_json} tests ${name} "{}")
string(JSON ref_json SET ${ref_json} tests ${name} archive \"${archive_name}\")
string(JSON ref_json SET ${ref_json} tests ${name} sha256 \"${hash}\")

if(gemini_version)
  string(JSON ref_json SET ${ref_json} tests ${name} gemini3d_version \"${gemini_version}\")
else()
  message(STATUS "${name}: omitted Gemini3D version from ${ref_json_file}")
endif()

if(gemini3d_tag)
  string(JSON ref_json SET ${ref_json} tests ${name} gemini3d_tag \"${gemini3d_tag}\")
endif()

if(pygemini_version)
  string(JSON ref_json SET ${ref_json} tests ${name} pygemini_version \"${pygemini_version}\")
endif()

if(gemini_features)
  string(JSON ref_json SET ${ref_json} tests ${name} gemini_features [])
  list(LENGTH gemini_features n)
  math(EXPR n "${n} - 1")
  foreach(i RANGE 0 ${n})
    list(GET gemini_features ${i} f)
    string(JSON ref_json SET ${ref_json} tests ${name} gemini_features ${i} \"${f}\")
  endforeach()
else()
  message(STATUS "${name}: omitted Gemini3D features from ${ref_json_file}")
endif()

file(WRITE ${ref_json_file} ${ref_json})

message(STATUS "Updated ${ref_json_file}")
