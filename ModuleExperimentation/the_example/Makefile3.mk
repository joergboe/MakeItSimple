# The rules for the example.
# Module dependencies expressed in generated rules.

# NOTE: The automatic variables $? and $^ are inaccurate if object file and cmi file have different prerequisites.
# (GNU Make 4.4.1)

# default target
my_program :

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# main.dep
main.o : main.cpp header2.h
CXX_OBJ_SRC_MOD_IF_REQ_LIST += main.o;main.cpp;-;0;module1;module2

# src1.dep
src1.o : src1.cpp header1.h
# as workaround for <https://savannah.gnu.org/bugs/?67825> try this
#src1.o gcm.cache/module1.gcm : src1.cpp header1.h
CXX_OBJ_SRC_MOD_IF_REQ_LIST += src1.o;src1.cpp;module1;1;module2

# src2.dep
src2.o : src2.cpp header2.h
# as workaround for <https://savannah.gnu.org/bugs/?67825> try this
#src2.o gcm.cache/module2.gcm : src2.cpp header2.h
CXX_OBJ_SRC_MOD_IF_REQ_LIST += src2.o;src2.cpp;module2;1

# not a module
main.o : main.cpp gcm.cache/module1.gcm gcm.cache/module2.gcm
	$(due_to)
	g++ -o main.o main.cpp -c -std=c++20 -fmodules
	@echo

# module1
src1.o gcm.cache/module1.gcm &: src1.cpp gcm.cache/module2.gcm
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
	rm -f my_program main.o src{1..2}.o
	rm -rf gcm.cache
