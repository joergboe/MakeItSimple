
#include "m3.hpp"
#include <iostream>

void hellom3() {
	std::cout << "Hello m3 !!!" << std::endl;
#	ifdef HELLOM3
	std::cout << HELLOM3 << std::endl;
#	endif
	return;
}
