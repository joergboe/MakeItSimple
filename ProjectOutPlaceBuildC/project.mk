# Provide the optional project specific settings here.

# Space separated list of directories with c++ source files
SRCDIRS := . src
# Use this code to determine the source directories recursively
#SRCDIR := .
#SRCDIRS := $(shell find $(SRCDIR) -type d)

# Optional: Space separated list of project internal include directories
INCDIRS := include

# Optional target name.
#TARGET := program1

# Optionale definitions
CPPFLAGS=-D 'MYHELLO="External define!"'

CFLAGS := -std=c11

# define one source file specific variable
# add 2 underscores because the real source name is ./m1.c
SRC__m1_cFLAGS = -D 'MYHELLO2="Hello World \#2"'
