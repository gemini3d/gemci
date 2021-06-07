cmake_minimum_required(VERSION 3.20...${CMAKE_VERSION})

set(PACKAGE_REMOTE dropbox)

function(upload_package archive out_dir name upload_root ref_json_file)
# NOTE: rclone copy default does not overwrite

# upload archive itself
# we use --checksum to avoid waste of data bandwidth as Dropbox requires recopy to set mod time of identical files
execute_process(
  COMMAND rclone copy ${archive} ${PACKAGE_REMOTE}:${upload_root} --verbose --checksum
  TIMEOUT 900
  RESOURCE_LOCK rclone_lock
  COMMAND_ERROR_IS_FATAL ANY)

cmake_path(GET archive FILENAME arc_name)

execute_process(
  COMMAND rclone link ${PACKAGE_REMOTE}:${upload_root}/${arc_name}
  TIMEOUT 30
  RESOURCE_LOCK rclone_lock
  OUTPUT_VARIABLE url
  OUTPUT_STRIP_TRAILING_WHITESPACE
  COMMAND_ERROR_IS_FATAL ANY)

if(PACKAGE_REMOTE STREQUAL dropbox)
  string(REPLACE "${arc_name}?dl=0" "${arc_name}?dl=1" url ${url})
endif()

file(READ ${ref_json_file} ref_json)
string(JSON ref_json SET ${ref_json} tests ${name} url \"${url}\")
file(WRITE ${ref_json_file} ${ref_json})

# update JSON with latest info
execute_process(
  COMMAND rclone copy ${ref_json_file} ${PACKAGE_REMOTE}:${upload_root} --verbose --checksum
  TIMEOUT 30
  RESOURCE_LOCK rclone_lock
  COMMAND_ERROR_IS_FATAL ANY)


if(false)
# NOTE: disabled this as it's very slow to upload many small plot files.

# upload plots directory to avoid needing to extract on local computers
# that is for others to quickly preview plots

# these options help for lots of small files (plots)
set(small_file_opts --fast-list --check-first)

execute_process(COMMAND rclone copy ${out_dir}/plots ${PACKAGE_REMOTE}:${upload_root}/plots/${name} --verbose --checksum ${small_file_opts}
  TIMEOUT 1800
  RESOURCE_LOCK rclone_lock
  COMMAND_ERROR_IS_FATAL ANY)

endif(false)

endfunction(upload_package)


upload_package(${archive} ${out_dir} ${name} ${upload_root} ${ref_json_file})
