function(gemini_run run_exe out_dir name label)

cmake_path(GET run_exe PARENT_PATH run_parent)
# for MSIS 2.0 and similar that need WORKING_DIRECTORY

set(run_cmd ${run_exe} ${out_dir} -mpiexec ${MPIEXEC_EXECUTABLE})

add_test(NAME "run:${name}"
  COMMAND ${run_cmd}
  WORKING_DIRECTORY ${run_parent})

set_tests_properties("run:${name}" PROPERTIES
  DISABLED $<NOT:$<BOOL:${run_exe}>>
  LABELS "run;${label}"
  FIXTURES_SETUP ${name}:run_fxt
  FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt"
  TIMEOUT 43200
  RESOURCE_LOCK cpu_mpi
  ENVIRONMENT GEMINI_SIMROOT=${GEMINI_SIMROOT})

endfunction(gemini_run)
