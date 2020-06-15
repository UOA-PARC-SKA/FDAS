include_directories(.)
include_directories(src)

add_executable(fdas
        src/host/main.cpp
        src/host/FDAS.cpp)
target_link_libraries(fdas npy aoclutils alteracl OpenCL elf)

add_custom_target(fdas-emu
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/fdas_config.h device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc -march=emulator -g -no-interleaving=default -o bin/fdas.aocx device/fdas.cl
        COMMENT "Compiling OpenCL code for emulation")

add_custom_target(fdas-report
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/fdas_config.h device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc -report -c -g -no-interleaving=default -o bin/fdas.aoco device/fdas.cl
        COMMENT "Generating HLS report")
