module;

#include <iostream>

export module m2;

#define GREETING "Greetings from m2\n"

export
void greetings() {
	std::cout << GREETING;
}
