# Provide the optional project specific settings here.

# ipbcpp -- C++ project   In Place Build     Build one executable from all %.cpp and %.cc source files in the project directory. 
project_type = ipbcpp

# Name of the executable
#TARGET := program

CXXFLAGS := -std=c++11

# Optionale definitions
CPPFLAGS = '-DMYHELLO="External define!"'

# define one source file specific variable
SRC_m1_cpp_FLAGS = '-DMYHELLO2="Hello World \#2"'
