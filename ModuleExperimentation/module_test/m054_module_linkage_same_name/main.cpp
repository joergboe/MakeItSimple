#include <iostream>

import lib_A;
import lib_B;

// If two declarations of an entity are attached to different modules, the program is ill-formed; no
// diagnostic is required if neither is reachable from the other!

int main(int, const char**) {
	std::cout << "Hello! Start main()\n";

	A a; //error: reference to ‘A’ is ambiguous
	a.print_name(); // This is A attached to global module
	return 0;
}