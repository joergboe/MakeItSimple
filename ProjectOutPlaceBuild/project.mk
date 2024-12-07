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
CPPFLAGS=-D 'MYHELLO="Alternative external Hello World! Danger: '\''.mks.tmp'\'' is in string!"'

CXXFLAGS := -std=c++11

# define one source file specific variable
# the real source name is src/m1.cpp
SRCsrc_m1_cppFLAGS = -D "MYHELLO2=\"MYHELLO2: Hello World from m1 \#2\""
SRCsrc_m2_cFLAGS = -D 'HELLOM2="HELLOM2: Hello World from m2 \#2"'
SRCsrc_m3_ccFLAGS = -D HELLOM3=\"HELLOM3:\ Hello\ World\ from\ m3\ \#2\"