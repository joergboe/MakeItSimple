#include <iostream>

import m1;

int main(int, const char**) {
	std::cout << greetings() << std::endl;
	//Macros from imported modules are invisible!
	//error: ‘VERSION’ was not declared in this scope
	//std::cout << "VERSION = " << VERSION << std::endl;
	return 0;
}
