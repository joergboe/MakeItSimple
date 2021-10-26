# provide the project specific settings here

# Name of the executable
TARGET := program

# Space separated list of directories with c++ source files
SRCDIRS := . src
# Use this code to determine the source directories recursively
#SRCDIR := .
#SRCDIRS := $(shell find $(SRCDIR) -type d)

# Directory used for build files (objects-files, dep-files)
BUILDDIR := build

# Target directory for the final executable
BINDIR := bin

# Optional: Space separated list of project internal include directories
INCDIRS := include

# Add optional variables here if necessary.