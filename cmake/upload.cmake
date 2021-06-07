set(PACKAGE_REMOTE dropbox)

function(upload_package archive out_dir name upload_root)
# NOTE: rclone copy default does not overwrite

# upload archive itself
execute_process(
  COMMAND rclone copy ${archive} ${PACKAGE_REMOTE}:${upload_root} --verbose
  COMMAND rclone copy ${ref_json_file} ${PACKAGE_REMOTE}:${upload_root} --verbose
  TIMEOUT 1800
  COMMAND_ERROR_IS_FATAL ANY)

# upload plots directory to avoid needing to extract on local computers
# that is for others to quickly preview plots

# these options help for lots of small files (plots)
set(small_file_opts --fast-list --check-first)

execute_process(COMMAND rclone copy ${out_dir}/plots ${PACKAGE_REMOTE}:${upload_root}/plots/${name} --verbose ${small_file_opts}
TIMEOUT 1800
COMMAND_ERROR_IS_FATAL ANY)

endfunction(upload_package)


upload_package(${archive} ${out_dir} ${name} ${upload_root})
