include_directories(src)
add_executable(fdas
        src/host/main.cpp)
target_link_libraries(fdas npy aoclutils alteracl OpenCL elf)
