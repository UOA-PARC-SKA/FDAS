cmake_minimum_required(VERSION 2.8)
project(skapint)

set(INTELFPGAOCLSDKROOT /opt/altera_pro/16.0/hld)
set(AOCL_BOARD_PACKAGE_ROOT ${INTELFPGAOCLSDKROOT}/board/nalla_pcie)

include_directories(FDAS/common/inc)
include_directories(FDAS/fdas/host/inc)
include_directories(${INTELFPGAOCLSDKROOT}/host/include)

link_directories(${AOCL_BOARD_PACKAGE_ROOT}/linux64/lib ${INTELFPGAOCLSDKROOT}/host/linux64/lib)

add_executable(fdas
        FDAS/common/inc/AOCL_Utils.h
        FDAS/common/src/AOCL_Utils.cpp
        FDAS/fdas/host/inc/fdas.h
        FDAS/fdas/host/inc/fft_config.h
        FDAS/fdas/host/inc/PcaCArray.h
        FDAS/fdas/host/src/main.cpp)

target_link_libraries(fdas alteracl OpenCL elf)
