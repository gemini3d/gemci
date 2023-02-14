function(gemini_run out_dir name label)

cmake_path(GET GEMINI_RUN PARENT_PATH run_parent)
# for MSIS 2.0 and similar that need WORKING_DIRECTORY

set(run_args ${out_dir} -mpiexec ${MPIEXEC_EXECUTABLE})
if(cpp)
  list(APPEND run_args -exe ${GEMINI_CXX_BIN_DEBUG})
else()
  list(APPEND run_args -exe ${GEMINI_Fortran_BIN_DEBUG})
endif()
if(mpi_nprocs)
  list(APPEND run_args -n ${mpi_nprocs})
endif()

# --- if array bounds checking exe available, use it first
# disable test if bounds check fails as result wouldn't be reliable due to incorrect code.
# We leave bounds test "disabled" if not available rather than hiding it, as it's a fundamental
# test and we want to noisily announce bounds checking wasn't available.
add_test(NAME "run_bounds_check:${name}"
COMMAND ${GEMINI_RUN_DEBUG} ${run_args} -dryrun
WORKING_DIRECTORY ${run_parent}
)
set_tests_properties("run_bounds_check:${name}" PROPERTIES
DISABLED ${${name}_DISABLED}
LABELS "run;${label}"
FIXTURES_SETUP ${name}:run_bounds_fxt
FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt"
RESOURCE_LOCK cpu_mpi
ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
)

set(run_args ${out_dir} -mpiexec ${MPIEXEC_EXECUTABLE})
if(cpp)
  list(APPEND run_args -exe ${GEMINI_CXX_BIN})
else()
  list(APPEND run_args -exe ${GEMINI_Fortran_BIN})
endif()

add_test(NAME "run:${name}"
COMMAND ${GEMINI_RUN} ${run_args}
WORKING_DIRECTORY ${run_parent}
)
set_tests_properties("run:${name}" PROPERTIES
LABELS "run;${label}"
FIXTURES_SETUP ${name}:run_fxt
FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt;${name}:run_bounds_fxt"
# list all fixtures in case gemini3d.run.debug is missing
DISABLED ${${name}_DISABLED}
RESOURCE_LOCK cpu_mpi
ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
)

endfunction(gemini_run)
