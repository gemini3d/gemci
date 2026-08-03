function(gemini_run out_dir name label)

set(run_args ${out_dir} -mpiexec ${MPIEXEC_EXECUTABLE})
if(cpp)
  list(APPEND run_args -exe $<TARGET_FILE:gemini_c.bin>)
else()
  list(APPEND run_args -exe $<TARGET_FILE:gemini.bin>)
endif()
if(mpi_nprocs)
  list(APPEND run_args -n ${mpi_nprocs})
endif()

# --- if array bounds checking exe available, use it first
# disable test if bounds check fails as result wouldn't be reliable due to incorrect code.
# We leave bounds test "disabled" if not available rather than hiding it, as it's a fundamental
# test and we want to noisily announce bounds checking wasn't available.
add_test(NAME "run_bounds_check:${name}" COMMAND gemini3d.run ${run_args} -dryrun)

# avoid overly-complicated generator expression
set(_run_bounds_disabled ${${name}_DISABLED})
set(_bounds_types Debug RelWithDebInfo)
if(NOT CMAKE_BUILD_TYPE IN_LIST _bounds_types)
  set(_run_bounds_disabled 1)
endif()

set_tests_properties("run_bounds_check:${name}" PROPERTIES
DISABLED ${_run_bounds_disabled}
LABELS "run;${label}"
FIXTURES_SETUP ${name}:run_bounds_fxt
FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt"
RESOURCE_LOCK cpu_mpi
ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
WORKING_DIRECTORY $<TARGET_FILE_DIR:gemini3d.run>
)

add_test(NAME "run:${name}" COMMAND gemini3d.run ${run_args})

set_tests_properties("run:${name}" PROPERTIES
LABELS "run;${label}"
FIXTURES_SETUP ${name}:run_fxt
FIXTURES_REQUIRED "${name}:setup_fxt;${name}:inputOK_fxt;${name}:run_bounds_fxt"
# list all fixtures in case gemini3d.run.debug is missing
DISABLED ${${name}_DISABLED}
RESOURCE_LOCK cpu_mpi
ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
WORKING_DIRECTORY $<TARGET_FILE_DIR:gemini3d.run>
)

endfunction()
