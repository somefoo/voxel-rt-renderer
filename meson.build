project('voxel-rt', 'cpp',
    default_options : ['cpp_std=c++17', 'buildtype=release'],
    version : '1.0.0',
    license : 'MIT License'
)

# Set up dependencies
zlib_dep = dependency('zlib', method : 'pkg-config')
sdl2_dep = dependency('sdl2', method : 'pkg-config')
opencl_dep = dependency('OpenCL', method : 'pkg-config')
opengl_dep = dependency('gl', method : 'pkg-config')

imgui_proj = subproject('imgui')
imgui_dep = imgui_proj.get_variable('imgui_dep')

# Include directories
inc = include_directories('subprojects/stb/')

modern_opencl_proj = subproject('modern-opencl')
modern_opencl_dep = modern_opencl_proj.get_variable('modern_opencl_dep')

# Sources
src = files([
    'src/main.cpp',
    'src/imgui_config/imgui_impl_sdl.h',
    'src/imgui_config/imgui_impl_sdl.cpp',
    'src/imgui_config/imgui_impl_opengl2.h',
    'src/imgui_config/imgui_impl_opengl2.cpp',
    'src/io/nrrd_loader.hpp',
    'src/io/nrrd_loader.cpp',
    'src/io/volume_block.hpp',
    'src/io/volume_block.cpp',
    'src/io/image_loader.hpp',
    'src/io/image_loader.cpp',
    'src/io/image.hpp',
    'src/io/image.cpp'
])

# Executable
exe = executable('run-voxel-rt', src, include_directories : inc, dependencies : [imgui_dep, zlib_dep, sdl2_dep, opencl_dep, opengl_dep, modern_opencl_dep], cpp_args : ['-DKERNEL_DIR="@0@"'.format(meson.current_source_dir() / 'kernels/')])



# If any custom flags are needed, you can set them like so:
# meson.add_global_arguments('-Og', language : 'cpp')
# meson.add_global_arguments('-O3', language : 'cpp')
