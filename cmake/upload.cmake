cmake_minimum_required(VERSION 3.21...3.24)

set(PACKAGE_REMOTE dropbox)

function(upload_package archive out_dir name upload_root ref_json_file)
# NOTE: rclone copy default does not overwrite

# upload archive itself
# we use --checksum to avoid waste of data bandwidth as Dropbox requires recopy to set mod time of identical files
execute_process(
COMMAND rclone copy ${archive} ${PACKAGE_REMOTE}:${upload_root} --verbose --checksum
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to upload ${archive} to ${PACKAGE_REMOTE}:${upload_root}")
endif()

cmake_path(GET archive FILENAME arc_name)

cmake_path(SET archive_path ${upload_root}/${arc_name})

# retrieve remote URL for this archive
execute_process(
COMMAND rclone link ${PACKAGE_REMOTE}:${archive_path}
OUTPUT_VARIABLE url
OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to link Rclone URL for ${PACKAGE_REMOTE}:${archive_path}")
endif()

if(PACKAGE_REMOTE STREQUAL dropbox)
  string(REPLACE "${arc_name}?dl=0" "${arc_name}?dl=1" url ${url})
endif()

message(STATUS "${archive_path} => ${url}")

file(READ ${ref_json_file} ref_json)
string(JSON ref_json SET ${ref_json} tests ${name} url \"${url}\")
file(WRITE ${ref_json_file} ${ref_json})

# update JSON with latest info
execute_process(
COMMAND rclone copy ${ref_json_file} ${PACKAGE_REMOTE}:${upload_root} --verbose --checksum
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to upload ${ref_json_file} with Rclone to ${PACKAGE_REMOTE}:${upload_root}")
endif()


if(false)
# NOTE: disabled this as it's very slow to upload many small plot files.

# upload plots directory to avoid needing to extract on local computers
# that is for others to quickly preview plots

# these options help for lots of small files (plots)
set(small_file_opts --fast-list --check-first)

execute_process(COMMAND rclone copy ${out_dir}/plots ${PACKAGE_REMOTE}:${upload_root}/plots/${name} --verbose --checksum ${small_file_opts}
TIMEOUT 1800
COMMAND_ERROR_IS_FATAL ANY
)

endif(false)

endfunction(upload_package)


upload_package(${archive} ${out_dir} ${name} ${upload_root} ${ref_json_file})
