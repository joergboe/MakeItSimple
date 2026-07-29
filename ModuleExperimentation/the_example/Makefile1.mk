# The finally required rules for the_example with default module mapping.

due_to = @echo 'Run target $@ - Due to $?'

my_program : main.o src1.o src2.o
	$(due_to)
	g++ -o my_program main.o src1.o src2.o -std=c++20 -fmodules
	@echo

main.o : main.cpp header2.h gcm.cache/module1.gcm gcm.cache/module2.gcm
	$(due_to)
	g++ -o main.o main.cpp -c -std=c++20 -fmodules
	@echo

src1.o gcm.cache/module1.gcm &: src1.cpp header1.h gcm.cache/module2.gcm
	$(due_to)
	g++ -o src1.o src1.cpp -c -std=c++20 -fmodules
	@echo

src2.o gcm.cache/module2.gcm &: src2.cpp header2.h
	$(due_to)
	g++ -o src2.o src2.cpp -c -std=c++20 -fmodules
	@echo

.PHONY : clean
clean :
	rm -f my_program main.o src1.o src2.o
	rm -rf gcm.cache
