module;

#include <iostream>

module Cyclic:A_impl;
import :A;
import :B;

void A::f(B& b) {
	std::cout << name() << " calling " << b.name() << std::endl;
}
