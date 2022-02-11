function(model_setup in_dir out_dir ref_root name label low_ram)

if(NOT label STREQUAL equilibrium)
  get_equil(${in_dir} ${name})
  message(VERBOSE "${name} setup depends on run fixture ${eq_name}")
endif()

if(python)

  add_test(NAME "setup:python:${name}"
  COMMAND ${Python_EXECUTABLE} -m gemini3d.model ${in_dir} ${out_dir} --gemini_root=${GEMINI_ROOT}
  WORKING_DIRECTORY ${in_dir}
  )

  set_tests_properties("setup:python:${name}" PROPERTIES
  LABELS "setup;python;${label}"
  FIXTURES_SETUP ${name}:setup_fxt
  TIMEOUT 900
  ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT}
  FIXTURES_REQUIRED "${name}:eq_fxt;${eq_name}:run_fxt"
  DISABLED ${${name}_DISABLED}
  )

  if(low_ram)
    set_tests_properties("setup:python:${name}" PROPERTIES RESOURCE_LOCK cpu_mpi)
  endif()

elseif(matlab)

  add_matlab_test("setup:matlab:${name}" "addpath('${in_dir}'); gemini3d.model.setup('${in_dir}', '${out_dir}')")

  set_tests_properties("setup:matlab:${name}" PROPERTIES
  LABELS "setup;matlab;${label}"
  FIXTURES_SETUP ${name}:setup_fxt
  TIMEOUT 900
  FIXTURES_REQUIRED "${name}:eq_fxt;${eq_name}:run_fxt"
  DISABLED $<NOT:$<BOOL:${MATGEMINI_DIR}>>
  )

  if(low_ram)
    set_tests_properties("setup:matlab:${name}" PROPERTIES RESOURCE_LOCK cpu_mpi)
  endif()
else()
  # Copy reference input files to output directory
  cmake_path(SET ref_dir ${ref_root}/${name})

  add_test(NAME "setup:copy:${name}"
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${ref_dir}/inputs ${out_dir}/inputs
  )

  set_tests_properties("setup:copy:${name}" PROPERTIES
  LABELS "setup;${label}"
  FIXTURES_SETUP "${name}:inputOK_fxt"
  TIMEOUT 60
  FIXTURES_REQUIRED "${name}:eq_fxt;${name}:download_fxt"
  DISABLED ${${name}_DISABLED}
  )
endif()

endfunction(model_setup)
