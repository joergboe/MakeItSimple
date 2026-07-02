module;

#include <iostream>

module m2;
import m1;

S2::S2() : v() {
	std::cout << "S2::S2()\n";
};
