include_directories(.)
include_directories(src)

add_executable(fdas_gtest
        src/host/main_gtest.cpp
        src/host/FDAS.cpp)
target_link_libraries(fdas_gtest npy alteracl OpenCL elf gtest)

# Synthesis flags
set(AOC_FLAGS -v -report -g -fmax=300 -no-interleaving=default)

# Architectural parameters
set(PARAM_E 5) # Number of FFT engines
set(PARAM_T 4) # Number of acceleration templates (= FOP rows) to process concurrently
set(PARAM_F 2) # Number of frequency bins (= FOP columns) to process concurrently

add_custom_target(fdas_gen
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/gen
        COMMAND pwd
        COMMAND python3 cl_codegen.py -c ${CMAKE_CURRENT_SOURCE_DIR}/src/device/fdas_gen.cl
                                      -g ${CMAKE_CURRENT_SOURCE_DIR}/src/host/gen_info.h
                                      --n-engines ${PARAM_E} --group-sz ${PARAM_T} --bundle-sz ${PARAM_F}
        COMMENT "Generating ${PARAM_E}x${PARAM_T}x${PARAM_F} architecture")

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
