function(get_plan_cpu plan_dir out_dir)

# gemini3d -plan needs these files to do the planning
foreach(f ${plan_dir}/inputs/config.nml ${plan_dir}/inputs/simsize.h5)
  if(NOT EXISTS ${out_dir}/inputs/${f})
    file(COPY ${f} DESTINATION ${out_dir}/inputs/)
  endif()
endforeach()

execute_process(COMMAND ${run_exe} ${out_dir} -plan
OUTPUT_VARIABLE plan_out
ERROR_VARIABLE plan_err
RESULT_VARIABLE _err
TIMEOUT 15
OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(_err EQUAL 0)
  string(REGEX MATCH "MPI images: ([0-9]+)" m ${plan_out})
  if(m)
    set(Ncpu ${CMAKE_MATCH_1})
  endif()
else()
  message(WARNING "gemini3d: ${name} plan failed, disabling: ${plan_err}")
  set(plan_cpu 0 PARENT_SCOPE)
  return()
endif()

set(plan_cpu ${Ncpu} PARENT_SCOPE)


endfunction(get_plan_cpu)
