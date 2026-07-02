# Usage
# cmake -B build
# cd build
# make

cmake_minimum_required(VERSION 3.10)

# set the project name and version
project(m025_include_include_header VERSION 1.0)

# specify the C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# LSP
set(CMAKE_EXPORT_COMPILE_COMMANDS True)

# Make
set(CMAKE_VERBOSE_MAKEFILE ON)

# add the executable
add_executable(main)
target_sources(main
	PRIVATE
	main.cpp src1.cpp src2.cpp
)

cmake_policy(SET CMP0076 OLD)
