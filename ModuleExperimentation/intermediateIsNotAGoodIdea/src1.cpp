module;

#include <iostream>
#include "header1.h"

export module module1;

export
void greeting() {
	std::cout << "Greeting from version " VERSION "\n";
}

export
void print_sum(float a, float b) {
	std::cout << "The sum from " << a << " and " << b << " is: " << a + b << std::endl;
}

export
void print_square(float a) {
	std::cout << "The square of " << a << " is: " << a * a << std::endl;
}
