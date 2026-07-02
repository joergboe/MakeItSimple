// User header unit in headers/module.h
// Definitions in src/module.cpp
// Imported in main.cpp and src/module.cpp

#include <iostream>

#define CONST1 55

import "headers/module.h";
//#include "headers/module.h"

int main(int, const char**) {
	std::cout << greeting() << std::endl;
	std::cout << "Version = " << version() << std::endl;
	std::cout << "another_string = " << another_string << std::endl;
	// Macros from header compiled units are visible!
	std::cout << "Visible macro from header unit: VERSION = " << VERSION << std::endl;
	std::cout << "CONST1 = " << CONST1 << std::endl;
	return 0;
}
