module;

#include <iostream>

#ifndef VERSION
#define VERSION="X.Y.Z"
#endif

export module greetings;

export
void greetings() {
	std::cout << "Hello World!\nVERSION=" VERSION << std::endl;
}
