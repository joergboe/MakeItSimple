module;

#include <iostream>
#include "header1.h"

import module$2;

export module module$1;

export
void greeting() {
	std::cout << "Greeting from version " VERSION "\n";
}

export
void print_sum(float a, float b) {
	std::cout << "The sum from " << a << " and " << b << " is: " << sum(a, b) << std::endl;
}

export
void print_square(float a) {
	std::cout << "The square of " << a << " is: " << square(a) << std::endl;
}

export
void print_circumference(float r) {
	std::cout << "A circle with radius " << r << " has circumference " << circumference(r) << std::endl;
}