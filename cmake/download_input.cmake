if(DEFINED ENV{CMAKE_MESSAGE_LOG_LEVEL})
  set(CMAKE_MESSAGE_LOG_LEVEL $ENV{CMAKE_MESSAGE_LOG_LEVEL})
endif()


function(download_input input_dir name)

string(REGEX REPLACE "[\\/]+$" "" input_dir "${input_dir}") # must strip trailing slash for cmake_path(... FILENAME) to work
cmake_path(GET input_dir FILENAME input_name)
if(NOT input_name)
  message(FATAL_ERROR "${name}: ${input_dir} seems malformed, could not get directory name ${input_name}")
endif()

file(READ ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/reference_url.json _refj)
string(JSON url GET ${_refj} ${input_name} url)
string(JSON archive_name GET ${_refj} ${input_name} archive)
# optional checksum
string(JSON hash ERROR_VARIABLE e GET ${_refj} ${input_name} sha256)

cmake_path(GET input_dir PARENT_PATH input_root)
cmake_path(APPEND archive ${input_root} ${archive_name})

# check if extracted data exists
if(IS_DIRECTORY ${input_dir})
  if(hash AND EXISTS ${input_dir}/sha256sum.txt)
    file(READ ${input_dir}/sha256sum.txt ext_hash)
    if(${ext_hash} STREQUAL ${hash})
      message(VERBOSE "${name}: ${input_name} extracted hash == JSON hash, no need to download.")
      return()
    else()
      message(STATUS "${name}: ${input_name} extracted hash ${ext_hash} != JSON hash ${hash}")
    endif()
  else()
    message(VERBOSE "${name}: ${input_name} hash not given and ${input_dir} exists, no need to download.")
    return()
  endif()
endif()

set(hash_ok true)
if(EXISTS ${archive} AND DEFINED hash)
  file(SHA256 ${archive} archive_hash)
  if(${archive_hash} STREQUAL ${hash})
    message(VERBOSE "${name}: archive hash == JSON hash, no need to download.")
  else()
    message(STATUS "${name}: archive hash ${archive_hash} != JSON hash ${hash}")
    set(hash_ok false)
  endif()
endif()

if(NOT EXISTS ${archive} OR NOT hash_ok)
  message(STATUS "${name}:DOWNLOAD: ${url} => ${archive}   ${hash}")
  if(hash)
    file(DOWNLOAD ${url} ${archive} TLS_VERIFY ON EXPECTED_HASH SHA256=${hash})
  else()
    file(DOWNLOAD ${url} ${archive} TLS_VERIFY ON)
  endif()
endif()

message(STATUS "${name}:EXTRACT: ${archive} => ${input_dir}")
file(ARCHIVE_EXTRACT INPUT ${archive} DESTINATION ${input_dir})

# to compare extracted contents and auto-update ref data
file(SHA256 ${archive} archive_hash)
file(WRITE ${input_dir}/sha256sum.txt ${archive_hash})

endfunction(download_input)


download_input(${input_dir} ${name})
