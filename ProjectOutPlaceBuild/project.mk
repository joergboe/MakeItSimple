# Provide the optional project specific settings here.

# opb    -- C/C++ project Out Place Build     Build one executable from all C++, C and assembler source files in all project source directories. 
project_type = opb

# Space separated list of directories with c++ source files
SRCDIRS := src
# Use this code to determine the source directories recursively
#SRCDIR := .
#SRCDIRS := $(shell find $(SRCDIR) -type d)


# Optional: Space separated list of project internal include directories
INCDIRS := include

# Add optional variables here if necessary.
TARGET := program1

# Optionale definitions
CPPFLAGS='-DMYHELLO="Alternative external Hello World! Danger: '\''.mks.tmp'\'' is in string!"'

CXXFLAGS := -std=c++11

# define one source file specific variable
# the real source name is src/m1.cpp
SRC_src_m1_cpp_FLAGS = "-DMYHELLO2=\"MYHELLO2: Hello World from m1 \#2\""
SRC_src_m2_c_FLAGS = '-DHELLOM2="HELLOM2: Hello World from m2 \#2"'
SRC_src_m3_cc_FLAGS = -DHELLOM3=\"HELLOM3:\ Hello\ World\ from\ m3\ \#2\"
