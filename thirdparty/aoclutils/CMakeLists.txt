add_library(aoclutils
        src/opencl.cpp
        src/options.cpp)

target_include_directories(aoclutils PUBLIC include)
