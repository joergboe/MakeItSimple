# Provide the optional project specific settings here.

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
CPPFLAGS=-D 'MYHELLO="External define!"'

CXXFLAGS := -std=c++11

# define one source file specific variable
# the real source name is src/m1.cpp
SRCsrc_m1_cppFLAGS = -D 'MYHELLO2="Hello World \#2"'
