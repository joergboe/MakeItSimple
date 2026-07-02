TARGET = main
SRCDIRS = ./
BUILDDIR = .
BINDIR = .
#CXXFLAGS = -std=c++20 -fmodules -flang-info-include-translate -flang-info-include-translate-not -flang-info-module-cmi -flang-info-include-translate=header
CXXFLAGS = -std=c++20 -fmodules -flang-info-include-translate -flang-info-module-cmi
CXX_USER_HEADER_UNITS = headers/module.h
