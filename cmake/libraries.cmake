set(_names gemini3d matgemini)

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json _libj)

foreach(n ${_names})
  foreach(t url tag)
    if(NOT ${n}_${t})
      string(JSON ${n}_${t} GET ${_libj} ${n} ${t})
    endif()
  endforeach()
endforeach()
