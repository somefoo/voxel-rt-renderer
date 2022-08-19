# FetchContent_MakeAvailable is available since CMake version 3.14
cmake_minimum_required(VERSION 3.14)

# Setting up dlib as an external package
set(HUNTER_PACKAGES imgui ZLIB SDL2)

include(FetchContent)
FetchContent_Declare(SetupHunter GIT_REPOSITORY https://github.com/cpp-pm/gate)
FetchContent_MakeAvailable(SetupHunter)

project(voxel-rt)
set (CMAKE_CXX_STANDARD 17)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS_DEBUG "-Og")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")



find_package(imgui CONFIG REQUIRED)
find_package(ZLIB REQUIRED)
find_package(SDL2 REQUIRED)
find_package(OpenGL REQUIRED)

add_subdirectory(lib/modern-opencl/)



add_executable(run-voxel-rt
  src/main.cpp
  src/imgui_config/imgui_impl_sdl.h
  src/imgui_config/imgui_impl_sdl.cpp
  
  src/imgui_config/imgui_impl_opengl2.h
  src/imgui_config/imgui_impl_opengl2.cpp


  src/io/nrrd_loader.hpp
  src/io/nrrd_loader.cpp
  src/io/volume_block.hpp
  src/io/volume_block.cpp

  src/io/image_loader.hpp
  src/io/image_loader.cpp
  src/io/image.hpp
  src/io/image.cpp
  )
target_include_directories(run-voxel-rt PRIVATE "${CMAKE_CURRENT_LIST_DIR}/lib/stb/")


target_compile_definitions(run-voxel-rt PRIVATE -DKERNEL_DIR="${CMAKE_CURRENT_LIST_DIR}/kernels/")

target_link_libraries(run-voxel-rt imgui::imgui ZLIB::zlib SDL2::SDL2 OpenGL::GL modern-opencl)
