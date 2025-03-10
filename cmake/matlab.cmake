find_package(Matlab COMPONENTS MAIN_PROGRAM REQUIRED)
if(Matlab_VERSION_STRING VERSION_LESS 24.2)
  message(WARNING "Matlab >= 24.2 required, found Matlab ${Matlab_VERSION_STRING}")
endif()

find_path(matgemini_SOURCE_DIR
NAMES buildfile.m
PATHS ${PROJECT_SOURCE_DIR}/mat_gemini/
REQUIRED
NO_DEFAULT_PATH
)

set(MATLABPATH "${matgemini_SOURCE_DIR};${matgemini_SOURCE_DIR}/matlab-stdlib/")
