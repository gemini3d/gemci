function(download_input input_dir name input_type arc_json_file)

string(REGEX REPLACE "[\\/]+$" "" input_dir "${input_dir}") # must strip trailing slash for cmake_path(... FILENAME) to work
cmake_path(GET input_dir FILENAME input_name)
if(NOT input_name)
  message(FATAL_ERROR "${name}: ${input_dir} seems malformed, could not get directory name ${input_name}")
endif()

file(READ ${arc_json_file} _refj)
string(JSON url GET ${_refj} ${input_type} ${input_name} url)
string(JSON archive_name GET ${_refj} ${input_type} ${input_name} archive)
string(JSON hash GET ${_refj} ${input_type} ${input_name} sha256)

cmake_path(GET input_dir PARENT_PATH input_root)
set(archive ${input_root}/${archive_name})

# check if extracted data exists
if(IS_DIRECTORY ${input_dir})

  if(EXISTS ${input_dir}/sha256sum.txt)
    file(READ ${input_dir}/sha256sum.txt ext_hash)
    if(${ext_hash} STREQUAL "${hash}")
      message(STATUS "${name}: ${input_name} extracted hash == JSON hash--skipping download.")
      return()
    else()
      message(STATUS "${name}: ${input_name} extracted hash ${ext_hash} != JSON hash ${hash}, re-downloading.")
    endif()
  else()
    message(STATUS "${name}: ${input_name} extracted hash not found, re-downloading.")
  endif()
endif()

# check if archive available
set(hash_ok false)
if(EXISTS ${archive})
  file(SHA256 ${archive} archive_hash)
  if(${archive_hash} STREQUAL "${hash}")
    message(STATUS "${name}: archive hash == JSON hash--skipping download.")
    set(hash_ok true)
  else()
    message(STATUS "${name}: archive hash ${archive_hash} != JSON hash ${hash}")
  endif()
endif()

if(NOT hash_ok)
  message(STATUS "${name}:DOWNLOAD: ${url} => ${archive}   ${hash}")
  file(DOWNLOAD ${url} ${archive} SHOW_PROGRESS
  EXPECTED_HASH SHA256=${hash}
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

message(STATUS "${name}:EXTRACT: ${archive} => ${input_dir}")
file(ARCHIVE_EXTRACT INPUT ${archive} DESTINATION ${input_dir})

# to compare extracted contents and auto-update ref data
file(SHA256 ${archive} archive_hash)
file(WRITE ${input_dir}/sha256sum.txt ${archive_hash})

endfunction(download_input)

if(ctest_run)
  download_input(${input_dir} ${name} ${input_type} ${arc_json_file})
endif()
