module;

#include <iostream>

export module lib_A;

int f() { return 0; } // f has module linkage
export int x = f();   // x equals 0

// A has module linkage
struct A {
	A() {
		std::cout << "A()@lib_A\n";
	}
	void print_name() {
		std::cout << "struct A@lib_A\n";
	}
};

export A a;
