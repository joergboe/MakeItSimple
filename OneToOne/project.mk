# sample project file

# otocpp -- C++ project   One To One     Build executable targets from each %.cpp and %.cc source file in the project directory. 
project_type = otocpp

# define one source file specific variable
SRC_m1_cpp_FLAGS = -DMYHELLO=\"Alternative\ external\ Hello!\" '-DMYHELLO2="Hello World \#2 Danger: '\''.mks.tmp'\'' is in string!"'
