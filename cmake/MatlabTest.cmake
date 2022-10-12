function(add_matlab_test name cmd)

add_test(NAME ${name}
COMMAND ${Matlab_MAIN_PROGRAM} -batch "${cmd}"
WORKING_DIRECTORY ${matgemini_SOURCE_DIR}
)

set_property(TEST ${name} PROPERTY ENVIRONMENT GEMINI_CIROOT=${GEMINI_CIROOT})
set_property(TEST ${name} PROPERTY ENVIRONMENT_MODIFICATION MATLABPATH=set:${MATLABPATH})

endfunction(add_matlab_test)
