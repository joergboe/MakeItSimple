TARGET = main
SRCDIRS = ./
BUILDDIR = .
BINDIR = .
#CXXFLAGS = -std=c++20 -fmodules
CXXFLAGS = -std=c++20 -fmodules -flang-info-include-translate -flang-info-module-cmi -flang-info-include-translate=header
CXX_USER_HEADER_UNITS = headers/module.h
