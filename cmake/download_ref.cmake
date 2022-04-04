function(download_ref name ref_root arc_json_file)

# sanity check to avoid making mess
if(NOT IS_DIRECTORY ${ref_root})
  message(FATAL_ERROR "${ref_root} is not a directory.")
endif()

file(READ ${arc_json_file} _refj)
string(JSON url GET ${_refj} tests ${name} url)
string(JSON archive_name GET ${_refj} tests ${name} archive)
string(JSON hash GET ${_refj} tests ${name} sha256)

cmake_path(SET ref_dir ${ref_root}/${name})
cmake_path(SET archive ${ref_root}/${archive_name})

# check if extracted data exists
if(IS_DIRECTORY ${ref_dir})
  if(EXISTS ${ref_dir}/sha256sum.txt)
    file(READ ${ref_dir}/sha256sum.txt ext_hash)
    if(${ext_hash} STREQUAL ${hash})
      message(STATUS "${name}: extracted hash == JSON hash--skipping download.")
      return()
    else()
      message(STATUS "${name}: extracted hash ${ext_hash} != JSON hash ${hash}, re-downloading.")
    endif()
  else()
    message(STATUS "${name}: extracted hash not found, re-downloading.")
  endif()
endif()

# check if archive available
set(hash_ok false)
if(EXISTS ${archive})
  file(SHA256 ${archive} archive_hash)
  if(${archive_hash} STREQUAL ${hash})
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
  INACTIVITY_TIMEOUT 15
  STATUS ret
  TLS_VERIFY ON
  )
  list(GET ret 0 stat)
  if(NOT stat EQUAL 0)
    list(GET ret 1 err)
    message(FATAL_ERROR "${url} download failed: ${err}")
  endif()
endif()

message(STATUS "${name}:EXTRACT: ${archive} => ${ref_dir}")
file(ARCHIVE_EXTRACT INPUT ${archive} DESTINATION ${ref_dir})

# to compare extracted contents and auto-update ref data
file(SHA256 ${archive} archive_hash)
file(WRITE ${ref_dir}/sha256sum.txt ${archive_hash})

endfunction(download_ref)

if(ctest_run)
  download_ref(${name} ${ref_root} ${arc_json_file})
endif()
