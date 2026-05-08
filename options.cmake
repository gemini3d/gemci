option(gemini3d_python "use Python for tests")
option(gemini3d_matlab "use Matlab (slower than Python)")
option(gemini3d_plot "plot difference between reference and computed")

option(gemini3d_hwm14 "use HWM14")
option(gemini3d_msis2 "use MSIS2")
option(gemini3d_glow "use GLOW" on)

option(dev "dev mode")

option(equil "run equilibrium (takes 10+ hours)")
option(package "package reference data .zst files")

set(Python_FIND_REGISTRY LAST)
# this avoids non-active conda from getting picked anyway on Windows


if(dev)
  set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED true)
endif()
