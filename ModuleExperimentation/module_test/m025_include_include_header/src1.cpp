#include "head1.h"
#include "head2.h"
#include "defines.h"

#include <iostream>

void greeting() {
	std::cout << "Greeting from src1.cpp VERSION = " << VERSION << std::endl;
}

void print_sum(int a, int b) {
	std::cout << "The sum from " << a << " and " << b << " is: " << sum(a, b) << std::endl;
}

void print_square(int a) {
	std::cout << "The square of " << a << " is: " << square(a) << std::endl;
}
