include_directories(.)
include_directories(src)

set(FDAS_MODE "FPGA" CACHE STRING "Set either to EMU or FPGA. The EMU mode uses reduced datasets to make software emulation of the OpenCL kernels tractable.")

if (NOT FDAS_MODE)
    # default to FPGA mode
    set(FDAS_MODE "FPGA" CACHE STRING "" FORCE)
endif()

add_definitions(-DFDAS_${FDAS_MODE})

add_executable(fdas_gtest
        src/host/main_gtest.cpp
        src/host/FDAS.cpp)
target_link_libraries(fdas_gtest npy alteracl OpenCL elf gtest)

add_executable(print_config
        src/host/print_config.cpp)

set(AOC_FLAGS -v -report -g -profile -no-interleaving=default -D FDAS_${FDAS_MODE})

if (FDAS_MODE STREQUAL "EMU")
add_custom_target(fdas_emu
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/fdas_config.h device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc -march=emulator ${AOC_FLAGS} -o bin/fdas_emu.aocx device/fdas.cl
        COMMENT "Generating emulator image")
endif()

add_custom_target(fdas_report
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/fdas_config.h device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc -rtl ${AOC_FLAGS} -o bin/fdas_rpt.aocr device/fdas.cl
        COMMENT "Generating HLS report")

if (FDAS_MODE STREQUAL "FPGA")
add_custom_target(fdas_synth
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/src/device device
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/fdas_config.h device
        COMMAND ${CMAKE_COMMAND} -E make_directory bin
        COMMAND aoc ${AOC_FLAGS} -o bin/fdas.aocx device/fdas.cl
        COMMENT "Generating bitstream")
endif()
