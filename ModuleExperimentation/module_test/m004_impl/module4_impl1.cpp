// Pure module implementation units are translated into objects files and no
// cmi file will be generated.

module; // global module fragment

#include <iostream>

#include "header1.h"

module m4; // module declaration not exported

void version() {
	std::cout << "VERSION = " << VERSION << std::endl;
}
