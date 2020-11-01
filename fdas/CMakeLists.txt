include_directories(.)
include_directories(src)

add_executable(fdas_gtest
        src/host/main_gtest.cpp
        src/host/FDAS.cpp)
target_link_libraries(fdas_gtest npy alteracl OpenCL elf gtest)

set(AOC_FLAGS -v -report -g -fmax=300 -no-interleaving=default)

add_custom_target(fdas_emu
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc -march=emulator ${AOC_FLAGS} -o bin/fdas.aocx device/fdas_gen.cl
        COMMENT "Generating emulator image")

add_custom_target(fdas_report
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc -rtl ${AOC_FLAGS} -o bin/fdas_rpt.aocr device/fdas_gen.cl
        COMMENT "Generating HLS report")

add_custom_target(fdas_synth
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc ${AOC_FLAGS} -o bin/fdas.aocx device/fdas_gen.cl
        COMMENT "Generating bitstream")
