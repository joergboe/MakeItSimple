TARGET = main
SRCDIRS = . src
BUILDDIR = .
BINDIR = .
CXXFLAGS = -std=c++20 -fmodules
#CXXFLAGS = -std=c++20 -fmodules -flang-info-include-translate -flang-info-module-cmi -fdump-lang-module
#CXXFLAGS = -std=c++20 -fmodules -flang-info-include-translate -flang-info-module-cmi
#CPPFLAGS = -I headers
CXX_USER_HEADER_UNITS = headers/module.h
