#include <iostream>

#include "header2.h"

import module1;
import module2;

int main(int, const char**) {
	greeting();
	print_sum(2, 3);
	print_square(5);
	std::cout << "The area of a circle with radius 0.5 is " << 0.5f * 0.5f * PI << std::endl;
	return 0;
}