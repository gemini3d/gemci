function(gemini_plot out_dir name label)

set(_n)

if(python)

list(APPEND _n "plot:python:${name}")

add_test(NAME "plot:python:${name}"
COMMAND ${Python_EXECUTABLE} -m gemini3d.plot ${out_dir} all
)
set_property(TEST "plot:python:${name}" PROPERTY LABELS "plot;python;${label}")

elseif(matlab)

list(APPEND _n "plot:matlab:${name}")

add_matlab_test("plot:matlab:${name}" "gemini3d.plot.plotall('${out_dir}', 'png')")
set_property(TEST "plot:matlab:${name}" PROPERTY LABELS "plot;matlab;${label}")

endif()

# --- properties
set_property(TEST ${_n} PROPERTY FIXTURES_REQUIRED ${name}:run_fxt)
set_property(TEST ${_n} PROPERTY FIXTURES_SETUP ${name}:plot_fxt)
set_property(TEST ${_n} PROPERTY REQUIRED_FILES "${out_dir}/inputs/config.nml;${out_dir}/output.nml")
set_property(TEST ${_n} PROPERTY ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT})
set_property(TEST ${_n} DISABLED ${${name}_DISABLED})

if(low_ram)
  set_property(TEST ${_n} PROPERTY RESOURCE_LOCK cpu_mpi)
endif()


endfunction(gemini_plot)
