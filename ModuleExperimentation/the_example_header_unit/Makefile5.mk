# The rules for the example with system and user header units.
# Module dependencies expressed in rules.

# Header translation uses a individual module map, thus auto import is effectively disabled.

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# default target
my_program :

# cstdio.dep
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += cstdio;cstdio.o;/usr/include/c++/15/cstdio;/usr/include/c++/15/cstdio;1

# cstddef
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += cstddef;cstddef.o;/usr/include/c++/15/cstddef;/usr/include/c++/15/cstddef;1

# iostream.dep
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += iostream;iostream.o;/usr/include/c++/15/iostream;1

# header2.h.dep
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += header2.h;header2.h.o;header2.h;./header2.h;1;/usr/include/c++/15/cstddef

# main.dep
main.o : main.cpp
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += -;main.o;main.cpp;-;0;module1;module2;/usr/include/c++/15/iostream;/usr/include/c++/15/cstdio;./header2.h

# src1.dep
src1.o : src1.cpp header1.h
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += -;src1.o;src1.cpp;module1;1;module2;/usr/include/c++/15/iostream

# src2.dep
src2.o : src2.cpp
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST += -;src2.o;src2.cpp;module2;1;./header2.h

# system header cmis
gcm.cache/usr/include/c++/15/iostream.gcm : /usr/include/c++/15/iostream gcm.cache/usr/include/c++/15/cstdio.gcm gcm.cache/usr/include/c++/15/cstddef.gcm
	$(due_to)
	@useCpu.sh -s 2
	g++ -x c++-system-header iostream -c -std=c++20 -fmodules
	@echo

gcm.cache/usr/include/c++/15/cstdio.gcm : /usr/include/c++/15/cstdio
	$(due_to)
	@useCpu.sh -s 2
	g++ -x c++-system-header cstdio -c -std=c++20 -fmodules
	@echo

gcm.cache/usr/include/c++/15/cstddef.gcm : /usr/include/c++/15/cstddef
	$(due_to)
	@useCpu.sh -s 2
	g++ -x c++-system-header cstddef -c -std=c++20 -fmodules
	@echo

# user header cmis
gcm.cache/,/header2.h.gcm : header2.h
	$(due_to)
	@useCpu.sh -s 2
	g++ -x c++-user-header header2.h -c -std=c++20 -fmodules
	@echo

# not a module
main.o : main.cpp gcm.cache/module1.gcm gcm.cache/module2.gcm gcm.cache/,/header2.h.gcm gcm.cache/usr/include/c++/15/iostream.gcm gcm.cache/usr/include/c++/15/cstddef.gcm gcm.cache/usr/include/c++/15/cstdio.gcm
	$(due_to)
	@useCpu.sh -s 2
	g++ -o main.o main.cpp -c -std=c++20 -fmodules
	@echo

# module1
src1.o gcm.cache/module1.gcm &: src1.cpp gcm.cache/module2.gcm gcm.cache/usr/include/c++/15/iostream.gcm
	$(due_to)
	@useCpu.sh -s 2
	g++ -o src1.o src1.cpp -c -std=c++20 -fmodules
	@echo

# module2
src2.o gcm.cache/module2.gcm &: src2.cpp gcm.cache/,/header2.h.gcm
	$(due_to)
	@useCpu.sh -s 2
	g++ -o src2.o src2.cpp -c -std=c++20 -fmodules
	@echo

# link all together
my_program : main.o src1.o src2.o
	$(due_to)
	@useCpu.sh -s 2
	g++ -o my_program main.o src1.o src2.o -std=c++20 -fmodules
	@echo

.PHONY :  clean
clean :
	rm -f my_program main.o src{1..2}.o
	rm -rf gcm.cache
