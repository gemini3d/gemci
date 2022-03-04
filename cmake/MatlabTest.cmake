function(add_matlab_test name cmd)

add_test(NAME ${name}
COMMAND ${Matlab_MAIN_PROGRAM} -batch "${cmd}"
WORKING_DIRECTORY ${matgemini_SOURCE_DIR}
)

set_tests_properties(${name} PROPERTIES
ENVIRONMENT "GEMINI_CIROOT=${GEMINI_CIROOT}"
ENVIRONMENT_MODIFICATION "MATLABPATH=set:${MATLABPATH}"
)

endfunction(add_matlab_test)
