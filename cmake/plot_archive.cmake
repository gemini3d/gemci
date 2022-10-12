function(plot_archive in out)

if(NOT IS_DIRECTORY ${in})
  message(STATUS "${in} does not exist, simulation must have matched expected data.")
  return()
endif()

cmake_path(GET out EXTENSION LAST_ONLY ARC_TYPE)

# need working_directory ${in} to avoid computer-specific relative paths
# use . not ${in} as last argument to avoid more relative path issues

if(ARC_TYPE STREQUAL .zst)
  set(arc_args --zstd)
elseif(ARC_TYPE STREQUAL .zip)
  set(arc_args --format=zip)
else()
  message(FATAL_ERROR "unknown archive type ${ARC_TYPE}")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} -E tar c ${out} ${arc_args} .
WORKING_DIRECTORY ${in}
COMMAND_ERROR_IS_FATAL ANY
)

# ensure an archive file was created (weak validation)
if(NOT EXISTS ${out})
  message(FATAL_ERROR "Archive ${out} was not created.")
endif()

file(SIZE ${out} fsize)
if(fsize LESS 10000)
  message(FATAL_ERROR "Archive ${out} may be malformed.")
endif()

endfunction(plot_archive)


plot_archive(${in} ${out})
