#include <iostream>

import lib_A;

// If two declarations of an entity are attached to different modules, the program is ill-formed; no
// diagnostic is required if neither is reachable from the other!
struct A { //error: redeclaring ‘struct A@lib_A’ in global module conflicts with import
	A() {
		std::cout << "A()\n";
	}
	void print_name() {
		std::cout << "class A\n";
	}
};

int main(int, const char**) {
	std::cout << "Hello! Start main()\n";
	std::cout << "x = " << x << std::endl;

	a.print_name();
	A a;
	a.print_name(); // This is A attached to global module
	return 0;
}