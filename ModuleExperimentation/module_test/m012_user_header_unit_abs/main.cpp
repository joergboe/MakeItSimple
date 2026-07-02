// User header unit in absolute path ..headers/module.h - includes defines.h
// Definitions in module.cpp
// System header unit

import <iostream>;

import "/home/joergboe/Experiments/C++/module_test/m012_user_header_unit_abs/headers/module.h";

int main(int, const char**) {
	std::cout << greeting() << std::endl;
	std::cout << "Version = " << version() << std::endl;
	// Macros from header compiled units are visible!
	std::cout << "VERSION = " << VERSION << std::endl;
	return 0;
}
