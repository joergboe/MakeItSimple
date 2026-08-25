# The rules for the_example with default module mapping.
# Variables are used to express the module dependencies in prerequisites.
# Database variables and dependency rules are defined simultaneously.

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

.SECONDEXPANSION :

# main.dep
main.o : main.cpp header2.h
main.o : $$(CXX_MOD_module1_CMI) $$(CXX_MOD_module2_CMI)

# src1.dep
src1.o : src1.cpp header1.h
src1.o : $$(CXX_MOD_module2_CMI)
CXX_SRC_MOD_IF_LIST += src1.cpp;module1;1

# src2.dep
src2.o : src2.cpp header2.h
CXX_SRC_MOD_IF_LIST += src2.cpp;module2;1

# automatic generated definitions
CXX_MOD_module1_CMI = gcm.cache/module1.gcm
CXX_MOD_module2_CMI = gcm.cache/module2.gcm
modsources = src1.cpp src2.cpp

# not a module
main.o : main.cpp
	$(due_to)
	g++ -o main.o main.cpp -c -std=c++20 -fmodules
	@echo

# module1
src1.o gcm.cache/module1.gcm &: src1.cpp
	$(due_to)
	g++ -o src1.o src1.cpp -c -std=c++20 -fmodules
	@echo

# module2
src2.o gcm.cache/module2.gcm &: src2.cpp
	$(due_to)
	g++ -o src2.o src2.cpp -c -std=c++20 -fmodules
	@echo

# link all together
my_program : main.o src1.o src2.o
	$(due_to)
	g++ -o my_program main.o src1.o src2.o -std=c++20 -fmodules
	@echo

.PHONY : clean
clean :
	rm -f my_program main.o src1.o src2.o
	rm -rf gcm.cache
