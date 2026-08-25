// User header headers/header1.h
// Definitions in src.cpp

#include <iostream>

#define MAIN 55

//#include "include/header1.h"
import "include/header1.h";

int main(int, const char**) {
	std::cout << greeting() << std::endl;
	std::cout << "Version = " << version() << std::endl;
	std::cout << "another_string = " << another_string << std::endl;
	std::cout << "Visible macro from header1.h : VERSION = " << VERSION << std::endl;
	return 0;
}
