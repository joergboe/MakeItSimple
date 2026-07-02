module;

#include <iostream>

export module mod;

#ifndef VARIANT_B
import sub1;
#else
import sub2;
#endif

export
void greetings() {
	std::cout << greeting;
}
