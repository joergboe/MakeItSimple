#include <iostream>

import lib_A;

// If two declarations of an entity are attached to different modules, the program is ill-formed; no
// diagnostic is required if neither is reachable from the other!
// seems to mean in one TU??
struct A {
	A() {
		std::cout << "A()\n";
	}
	void print_name() {
		std::cout << "struct A\n";
	}
};

int main(int, const char**) {
	std::cout << "Hello! Start main()\n";
	std::cout << "x = " << x << std::endl;

	//!! members of a are implicitly known, even if A@lib_A is not exported !!
	a.print_name();
	A a;
	a.print_name(); // This is A attached to global module
	return 0;
}
