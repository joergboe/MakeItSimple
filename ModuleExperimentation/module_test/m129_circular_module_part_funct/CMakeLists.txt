# Usage:
#cmake -S . -B build -G Ninja
#cmake --build build/ -v

cmake_minimum_required(VERSION 3.31)

project(m129_circular_module_part_funct VERSION 1.0)

set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
#set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
#add_compile_options(-fmodules-ts)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_VERBOSE_MAKEFILE ON)

#set(CMAKE_CXX_COMPILER clang++)
#set(CXX clang++)


add_executable(main)
#set_property(SOURCE m1.cpp PROPERTY CXX_SCAN_FOR_MODULES)
#add_library(module1 OBJECT)
target_sources(main
	PUBLIC
	main.cpp a.cpp b.cpp a_impl.cpp b_impl.cpp
	PUBLIC
	FILE_SET CXX_MODULES FILES
	a.cpp b.cpp
)
