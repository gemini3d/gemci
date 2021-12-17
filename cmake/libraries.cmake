set(_names gemini3d matgemini)

file(READ ${PROJECT_SOURCE_DIR}/libraries.json _libj)

foreach(n ${_names})
  foreach(t url tag)
    string(JSON ${n}_${t} GET ${_libj} ${n} ${t})
  endforeach()
endforeach()
