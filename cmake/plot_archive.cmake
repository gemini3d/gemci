function(plot_archive in out)

if(NOT IS_DIRECTORY ${in})
  message(STATUS "${in} does not exist, simulation must have matched expected data.")
  return()
endif()

if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.31)
  file(ARCHIVE_CREATE
  OUTPUT ${out}
  PATHS ${in}
  COMPRESSION Zstd
  COMPRESSION_LEVEL 3
  WORKING_DIRECTORY ${in}
  )
  # need WORKING_DIRECTORY ${in} to avoid computer-specific relative paths
else()
  # need working_directory ${in} to avoid computer-specific relative paths
  # use . not ${in} as last argument to avoid more relative path issues

  execute_process(
  COMMAND ${CMAKE_COMMAND} -E tar c ${out} --zstd .
  WORKING_DIRECTORY ${in}
  COMMAND_ERROR_IS_FATAL ANY
  )
endif()

# ensure an archive file was created (weak validation)
file(SIZE ${out} fsize)
if(fsize LESS 10000)
  message(FATAL_ERROR "Archive ${out} may be malformed.")
endif()

endfunction(plot_archive)


plot_archive(${in} ${out})
