add_library(npy
        npy_dummy.cpp)
# Note: CMake >= 3.1 supports `add_library(npy INTERFACE)` to model header-only
#       libraries, without dummy source files.

target_include_directories(npy PUBLIC include)
