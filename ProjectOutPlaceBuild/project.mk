# provide the project specific settings here
TARGET := program
SRCDIRS := . src
BUILDDIR := build
BINDIR := bin

INCDIRS := include
# with this code the include directories are automatically detected
#INCDIRS := $(shell find $(SRCDIRS) -type d)

# Add optional variables here if necessary.