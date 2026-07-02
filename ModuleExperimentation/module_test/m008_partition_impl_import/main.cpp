/*
 * Module with interface and implementation partitions
 * and import partition units
 */

#include <iostream>

import math;

int main() {
	std::cout << "add(3, 4): " << add(3, 4) << std::endl;
	std::cout << "mul(3, 4): " << mul(3, 4) << std::endl;
	std::cout << "circumference(2.0): " << circumference(2.0f) << std::endl;
	std::cout << "pi: " << get_pi() << std::endl;
}
