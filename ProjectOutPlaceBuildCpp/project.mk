# Provide the optional project specific settings here.

# Space separated list of directories with c++ source files
SRCDIRS := . src
# Use this code to determine the source directories recursively
#SRCDIR := .
#SRCDIRS := $(shell find $(SRCDIR) -type d)

# Optional: Space separated list of project internal include directories
INCDIRS := include

# Optional target name.
TARGET := program1

# Optionale definitions
CPPFLAGS=-D 'MYHELLO="External define!"'

CXXFLAGS := -std=c++11

# define one source file specific variable
# do not add 2 underscores because ./ is stripped from the real source name ./m1.cpp
SRC_m1_cpp_FLAGS = -D 'MYHELLO2="Hello World \#2"'
