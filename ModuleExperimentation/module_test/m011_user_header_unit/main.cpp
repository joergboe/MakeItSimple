// User header unit in headers/module.h - includes defines.h
// definition of another string in defines.h
// Definitions in module.cpp


#include <iostream>

import "headers/module.h";

int main(int, const char**) {
	std::cout << greeting() << std::endl;
	std::cout << "Version = " << version() << std::endl;
	std::cout << "another_string = " << another_string << std::endl;
	// Macros from header compiled units are visible!
	std::cout << "VERSION = " << VERSION << std::endl;
	return 0;
}
