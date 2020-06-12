cmake_minimum_required(VERSION 2.8)
project(skapint)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

include_directories($ENV{INTELFPGAOCLSDKROOT}/host/include)
link_directories($ENV{AOCL_BOARD_PACKAGE_ROOT}/linux64/lib $ENV{INTELFPGAOCLSDKROOT}/host/linux64/lib)

add_subdirectory(thirdparty/aoclutils)
add_subdirectory(thirdparty/libnpy)
add_subdirectory(fdas)
