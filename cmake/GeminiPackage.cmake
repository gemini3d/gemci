set(ARC_TYPE zst)
# prefer .zst to .zstd as tools are better at recognizing .zst


function(gemini_package GEMINI_CIROOT out_dir ref_json_file name label)

set(archive ${upload_root}/${name}.${ARC_TYPE})
set(data_dir ${GEMINI_CIROOT}/${name})

string(REPLACE ";" "\\;" GEMINI_FEATURES "${GEMINI_FEATURES}")

add_test(NAME "archive:${name}"
COMMAND ${CMAKE_COMMAND} -Din:PATH=${data_dir} -Dout:FILEPATH=${archive}
-Dref_json_file:FILEPATH=${ref_json_file}
-Dgemini_version=${GEMINI_VERSION}
-Dgemini_features=${GEMINI_FEATURES}
-Dpygemini_version=${PYGEMINI_VERSION}
-Dname=${name}
-P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/archive.cmake
)

set_tests_properties("archive:${name}" PROPERTIES
FIXTURES_REQUIRED "${name}:run_fxt;${name}:plot_fxt"
FIXTURES_SETUP ${name}:upload_fxt
DISABLED ${${name}_DISABLED}
RESOURCE_LOCK package_rclone # prevent race ref_data.json between archive.cmake and upload.cmake
LABELS "package;${label}"
REQUIRED_FILES "${data_dir}/inputs/config.nml;${data_dir}/output.nml"
)

find_program(rclone NAMES rclone)
if(NOT rclone)
  return()
endif()

add_test(NAME "upload:${name}"
COMMAND ${CMAKE_COMMAND} -Darchive:FILEPATH=${archive} -Dout_dir:PATH=${out_dir}
-Dref_json_file:FILEPATH=${ref_json_file}
-Dname=${name}
-Dupload_root:PATH=gemini_upload-${package_date}
-P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/upload.cmake
)

set_tests_properties("upload:${name}" PROPERTIES
FIXTURES_REQUIRED ${name}:upload_fxt
LABELS "package;${label}"
REQUIRED_FILES ${archive}
RESOURCE_LOCK package_rclone # prevent race ref_data.json between archive.cmake and upload.cmake and rclone API limit
DISABLED $<NOT:$<BOOL:${rclone}>>
)
# takes a long time to upload many small files

endfunction(gemini_package)
