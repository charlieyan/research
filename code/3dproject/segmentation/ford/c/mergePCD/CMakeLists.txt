cmake_minimum_required(VERSION 2.8 FATAL_ERROR)

project(mergeAll)

find_package(PCL 1.6 REQUIRED)

include_directories(${PCL_INCLUDE_DIRS})
link_directories(${PCL_LIBRARY_DIRS})
add_definitions(${PCL_DEFINITIONS})

add_executable (mergeAll mergeAll.cpp)
set (CMAKE_CXX_FLAGS "-w")
target_link_libraries (mergeAll ${PCL_LIBRARIES})
