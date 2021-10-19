function(input_setup in_dir out_dir name label equil)

get_equil(${in_dir} ${name})

if(NOT equil)
  add_test(NAME "setup:download_equilibrium:${name}"
  COMMAND ${CMAKE_COMMAND} -Dinput_dir:PATH=${eq_dir} -Dname=${name} -Dinput_type=tests -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/download_input.cmake)

  set_tests_properties("setup:download_equilibrium:${name}" PROPERTIES
  LABELS "download;${label}"
  REQUIRED_FILES ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ref_data.json
  TIMEOUT 900
  FIXTURES_SETUP ${name}:eq_fxt
  RESOURCE_LOCK download_lock)
endif()
# get neutral input directory, if present
parse_nml(${nml_file} "source_dir" "path")
if(NOT source_dir)
  return()
endif()

add_test(NAME "setup:download_neutral:${name}"
COMMAND ${CMAKE_COMMAND} -Dinput_dir:PATH=${source_dir} -Dname=${name} -Dinput_type=neutrals -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/download_input.cmake)

set_tests_properties("setup:download_neutral:${name}" PROPERTIES
LABELS "download;${label}"
REQUIRED_FILES ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ref_data.json
TIMEOUT 7200
FIXTURES_SETUP ${name}:eq_fxt  # no need for distinct fixture
RESOURCE_LOCK download_lock)



endfunction(input_setup)
