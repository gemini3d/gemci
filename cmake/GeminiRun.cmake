function(gemini_run out_dir name label)

cmake_path(GET GEMINI_RUN PARENT_PATH run_parent)
# for MSIS 2.0 and similar that need WORKING_DIRECTORY

set(run_args ${out_dir} -mpiexec ${MPIEXEC_EXECUTABLE})

# --- if array bounds checking exe available, use it first
# disable test if bounds check fails as result wouldn't be reliable due to incorrect code.
# We leave bounds test "disabled" if not available rather than hiding it, as it's a fundamental
# test and we want to noisily announce bounds checking wasn't available.
add_test(NAME "run_bounds_check:${name}"
  COMMAND ${GEMINI_RUN_DEBUG} ${run_args} -dryrun
  WORKING_DIRECTORY ${run_parent}
)
set_tests_properties("run_bounds_check:${name}" PROPERTIES
  DISABLED $<NOT:$<BOOL:${GEMINI_RUN_BOUNDS_CHECK}>>
  LABELS "run;${label}"
  FIXTURES_SETUP ${name}:run_bounds_fxt
  FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt"
  TIMEOUT 180
  RESOURCE_LOCK cpu_mpi
  ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
)

add_test(NAME "run:${name}"
  COMMAND ${GEMINI_RUN} ${run_args}
  WORKING_DIRECTORY ${run_parent}
)
set_tests_properties("run:${name}" PROPERTIES
  LABELS "run;${label}"
  FIXTURES_SETUP ${name}:run_fxt
  FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt;${name}:run_bounds_fxt"  # list them all in case .debug exe missing
  DISABLED ${${name}_DISABLED}
  TIMEOUT 43200
  RESOURCE_LOCK cpu_mpi
  ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
)

endfunction(gemini_run)
