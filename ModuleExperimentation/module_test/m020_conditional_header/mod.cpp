#ifndef VARIANT_B
#include "h1.h"
#else
#include "h2.h"
#endif

#include <iostream>

void greetings() {
	std::cout << GREETING;
}
