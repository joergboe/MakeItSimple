# The rules for the example expressed with intermediate
# Is not a good idea because it is difficult to detect duplicate module definitions

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

my_program : main.o src1.o src2.o
	$(due_to)
	g++ -o my_program main.o src1.o src2.o -std=c++20 -fmodules

#main.dep
main.o : main.cpp header2.h
main.o : module1.c++-module module2.c++-module

#src1.dep
src1.o gcm.cache/module1.gcm : src1.cpp header1.h
module1.c++-module : gcm.cache/module1.gcm
.INTERMEDIATE : module1.c++-module

#src2.dep
src2.o gcm.cache/module2.gcm : src2.cpp header2.h
module2.c++-module : gcm.cache/module2.gcm
.INTERMEDIATE : module2.c++-module

# not a module
main.o : main.cpp
	$(due_to)
	g++ -o main.o main.cpp -c -std=c++20 -fmodules
# module1
src1.o gcm.cache/module1.gcm &: src1.cpp
	$(due_to)
	g++ -o src1.o src1.cpp -c -std=c++20 -fmodules
# module2
src2.o gcm.cache/module2.gcm &: src2.cpp
	$(due_to)
	g++ -o src2.o src2.cpp -c -std=c++20 -fmodules

.PHONY : clean
clean :
	rm -f my_program main.o src{1..2}.o
	rm -rf gcm.cache
	rm -f *.c++module
