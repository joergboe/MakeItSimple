main: main.o src1.o src2.o
	g++ -o main main.o src1.o src2.o
main.o: main.cpp head1.h
	g++ -o main.o main.cpp -c
src1.o: src1.cpp head1.h head2.h defines.h
	g++ -o src1.o src1.cpp -c
src2.o: src2.cpp head2.h
	g++ -o src2.o src2.cpp -c
