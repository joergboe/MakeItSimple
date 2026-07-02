module;

#include <iostream>

# include "defines.h"

import module2;

export module module1;

export
void greeting() {
	std::cout << "Greeting from src1.cpp VERSION = " << VERSION << std::endl;
}

export
void print_sum(int a, int b) {
	std::cout << "The sum from " << a << " and " << b << " is: " << sum(a, b) << std::endl;
}

export
void print_square(int a) {
	std::cout << "The square of " << a << " is: " << square(a) << std::endl;
}
