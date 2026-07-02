module;

#include <iostream>

export module m1;

#define GREETING "Greetings from m1\n"

export
void greetings() {
	std::cout << GREETING;
}
