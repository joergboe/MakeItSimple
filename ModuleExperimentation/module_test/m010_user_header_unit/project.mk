TARGET = main
SRCDIRS = ./
BUILDDIR = .
BINDIR = .
CXXFLAGS = -std=c++20 -fmodules
CXXFLAGS += -flang-info-include-translate -flang-info-module-cmi
CXX_USER_HEADER_UNITS = include/header1.h
