function(compare_output compare_exe out_dir ref_root name label)

cmake_path(APPEND ref_dir ${ref_root} ${name})

set(cmd ${compare_exe} ${out_dir} ${ref_dir} -which out)
if(matlab AND MATGEMINI_DIR)
  list(APPEND cmd -matlab)
elseif(python AND py_ok)
  list(APPEND cmd -python)
endif()

add_test(NAME compare:output:${name} COMMAND ${cmd})

set_tests_properties(compare:output:${name} PROPERTIES
LABELS "compare;${label}"
FIXTURES_REQUIRED "${name}:run_fxt;${name}:download_fxt"
FIXTURES_SETUP ${name}:plotdiff_fxt
TIMEOUT 300
ENVIRONMENT "${MATLABPATH};GEMINI_CIROOT=${GEMINI_CIROOT}")

add_test(NAME plotdiff:output:${name}
COMMAND ${CMAKE_COMMAND} -Din:PATH=${out_dir}/plot_diff -Dout:FILEPATH=${out_dir}/plot_diff.zip -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/plot_archive.cmake)

set_tests_properties(plotdiff:output:${name} PROPERTIES
TIMEOUT 30
FIXTURES_CLEANUP ${name}:plotdiff_fxt
LABELS "compare;plot;${label}"
REQUIRED_FILES ${out_dir}/output.nml
)

endfunction(compare_output)


function(compare_input compare_exe out_dir ref_root name label)

cmake_path(APPEND ref_dir ${ref_root} ${name})

set(cmd ${compare_exe} ${out_dir} ${ref_dir} -which in)
if(matlab AND MATGEMINI_DIR)
  list(APPEND cmd -matlab)
elseif(python AND py_ok)
  list(APPEND cmd -python)
endif()

add_test(NAME compare:input:${name} COMMAND ${cmd})

set_tests_properties(compare:input:${name} PROPERTIES
LABELS "compare;${label}"
FIXTURES_REQUIRED ${name}:download_fxt
FIXTURES_SETUP ${name}:inputOK_fxt
TIMEOUT 600
ENVIRONMENT "${MATLABPATH};GEMINI_CIROOT=${GEMINI_CIROOT}")

endfunction(compare_input)


function(compare_download out_dir ref_root name label)

add_test(NAME compare:download:${name}
COMMAND ${CMAKE_COMMAND} -Dname=${name} -Dref_root:PATH=${ref_root} -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/download_ref.cmake)

set_tests_properties(compare:download:${name} PROPERTIES
FIXTURES_SETUP ${name}:download_fxt
FIXTURES_REQUIRED ${name}:setup_fxt
# REQUIRED_FILES ${out_dir}/inputs/config.nml
LABELS "download;${label}"
RESOURCE_LOCK download_lock
TIMEOUT 600
)
# not required:
# * output.nml since we may want to compare just input without running sim
# * config.nml since we may choose not to generate input

endfunction(compare_download)
