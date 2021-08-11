if(DEFINED ENV{CMAKE_MESSAGE_LOG_LEVEL})
  set(CMAKE_MESSAGE_LOG_LEVEL $ENV{CMAKE_MESSAGE_LOG_LEVEL})
else()
set(CMAKE_MESSAGE_LOG_LEVEL "VERBOSE")
endif()

function(download_ref name ref_root)

# sanity check to avoid making mess
if(NOT IS_DIRECTORY ${ref_root})
  message(FATAL_ERROR "must provide 'ref_root' e.g. ~/simulations/ref_data")
endif()

file(READ ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/reference_url.json _refj)
string(JSON url GET ${_refj} ${name} url)
string(JSON archive_name GET ${_refj} ${name} archive)
# optional checksum
string(JSON hash ERROR_VARIABLE e GET ${_refj} ${name} sha256)

cmake_path(APPEND ref_dir ${ref_root} ${name})
cmake_path(APPEND archive ${ref_root} ${archive_name})

# check if extracted data exists
if(IS_DIRECTORY ${ref_dir})
  if(hash AND EXISTS ${ref_dir}/sha256sum.txt)
    file(READ ${ref_dir}/sha256sum.txt ext_hash)
    if(${ext_hash} STREQUAL ${hash})
      message(VERBOSE "${name}: extracted hash == JSON hash, no need to download.")
      return()
    else()
      message(STATUS "${name}: extracted hash ${ext_hash} != JSON hash ${hash}")
    endif()
  else()
    message(VERBOSE "${name}: JSON hash not given and ${ref_dir} exists, no need to download.")
    return()
  endif()
endif()

# check if archive available
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


message(STATUS "${name}:EXTRACT: ${archive} => ${ref_dir}")
file(ARCHIVE_EXTRACT INPUT ${archive} DESTINATION ${ref_dir})

# to compare extracted contents and auto-update ref data
file(SHA256 ${archive} archive_hash)
file(WRITE ${ref_dir}/sha256sum.txt ${archive_hash})

endfunction(download_ref)


download_ref(${name} ${ref_root})
