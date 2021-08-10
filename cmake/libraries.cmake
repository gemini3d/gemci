set(_names matgemini)

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json _libj)

foreach(n ${_names})
  foreach(t git tag zip sha1)
    string(JSON m ERROR_VARIABLE e GET ${_libj} ${n} ${t})
    if(m)
      set(${n}_${t} ${m})
    endif()
  endforeach()
endforeach()
