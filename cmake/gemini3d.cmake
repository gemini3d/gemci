include(FetchContent)

set(GEMINI_FEATURES "REALBITS:64" MPI HDF5)
if(gemini3d_glow)
  list(APPEND GEMINI_FEATURES GLOW)
endif()
if(gemini3d_msis2)
  list(APPEND GEMINI_FEATURES MSIS2)
endif()
if(gemini3d_hwm14)
  list(APPEND GEMINI_FEATURES HWM14)
endif()

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json lib_json)

if(NOT DEFINED gemini3d_url OR gemini3d_url STREQUAL "")
  string(JSON gemini3d_url GET ${lib_json} gemini3d url)
endif()

if(NOT DEFINED gemini3d_tag OR gemini3d_tag STREQUAL "")
  string(JSON gemini3d_tag GET ${lib_json} gemini3d tag)
endif()

message(STATUS "Gemini3D from URL: ${gemini3d_url} tag: ${gemini3d_tag}")

set(gemini3d_BUILD_TESTING OFF)

FetchContent_Declare(GEMINI3D GIT_REPOSITORY ${gemini3d_url} GIT_TAG ${gemini3d_tag})

FetchContent_MakeAvailable(GEMINI3D)


set(GEMINI_ROOT ${gemini3d_BINARY_DIR})
