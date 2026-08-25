#CXX = g++-15
TARGET = main
SRCDIRS = ./
BUILDDIR = .
BINDIR = .
CXXFLAGS = -std=c++20 -fmodules
CXXFLAGS += -flang-info-include-translate -flang-info-module-cmi
CXM_SYSTEM_HEADER_UNITS = iostream cstdlib
