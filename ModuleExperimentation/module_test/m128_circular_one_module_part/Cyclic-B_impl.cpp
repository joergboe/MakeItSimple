module;

#include <iostream>

module Cyclic:B_impl;
import :B;
import :A;

void B::f(A& a) {
	std::cout << name() << " calling " << a.name() << std::endl;
}
