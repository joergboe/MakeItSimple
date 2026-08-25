# The rules for the_example with custom module mapping.
# Variables are used to express the module dependencies in prerequisites.
# Database variables are defined in front of the dependency rules.

# NOTE: The automatic variables $? and $^ are inaccurate if object file and cmi file have different prerequisites.
# (GNU Make 4.4.1)

# the database
CXM_SRC_MOD_IF_LIST += src1.cpp;module1;1
CXM_SRC_MOD_IF_LIST += src2.cpp;module2;1

# generated variables
CXM_MOD_module1_CMI = modulecache/module1.gcm
CXM_MOD_module2_CMI = modulecache/module2.gcm
modsources = src1.cpp src2.cpp
define modulemap ::=
module1 modulecache/module1.gcm
module2 modulecache/module2.gcm

endef

# write the modulemap
$(file > module-map.txt,$(modulemap))

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

# main.dep
main.o : main.cpp header2.h
main.o : $(CXM_MOD_module1_CMI) $(CXM_MOD_module2_CMI)

# src1.dep
src1.o : src1.cpp header1.h
src1.o $(CXM_MOD_module1_CMI) : $(CXM_MOD_module2_CMI)

# src2.dep
src2.o : src2.cpp header2.h

# not a module
main.o : main.cpp
	$(due_to)
	g++ -o main.o main.cpp -c -std=c++20 -fmodules -fmodule-mapper=module-map.txt
	@echo

# module1
src1.o modulecache/module1.gcm &: src1.cpp
	$(due_to)
	g++ -o src1.o src1.cpp -c -std=c++20 -fmodules -fmodule-mapper=module-map.txt
	@echo

# module2
src2.o modulecache/module2.gcm &: src2.cpp
	$(due_to)
	g++ -o src2.o src2.cpp -c -std=c++20 -fmodules -fmodule-mapper=module-map.txt
	@echo

# link all together
my_program : main.o src1.o src2.o
	$(due_to)
	g++ -o my_program main.o src1.o src2.o -std=c++20 -fmodules
	@echo

.PHONY : clean
clean :
	rm -f my_program main.o src1.o src2.o
	rm -f module-map.txt
	rm -rf modulecache
