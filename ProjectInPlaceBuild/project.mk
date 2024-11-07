# Provide the optional project specific settings here.

# Name of the executable
#TARGET := program

CXXFLAGS := -std=c++11

# Optionale definitions
CPPFLAGS=-D 'MYHELLO="External define!"'

# define one source file specific variable
SRCm1_cppFLAGS = -D 'MYHELLO2="Hello World \#2"'
