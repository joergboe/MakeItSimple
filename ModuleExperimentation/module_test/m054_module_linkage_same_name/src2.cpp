module;

#include <iostream>

export module lib_B;

export struct A {
	A() {
		std::cout << "A()@lib_A\n";
	}
	void print_name() {
		std::cout << "class A@lib_A\n";
	}
};

export A b;
