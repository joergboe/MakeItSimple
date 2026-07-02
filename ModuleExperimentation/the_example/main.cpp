#include <iostream>

#include "header2.h"

import module1;
import module2;

int main(int, const char**) {
	greeting();
	print_sum(2, 3);
	print_square(5);
	print_circumference(0.5f);
	std::cout << "The area of a circle with radius 0.5 is " << square(0.5f) * PI << std::endl;
	return 0;
}