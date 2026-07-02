// Entities in private module fragments can not be exported.
module;

#include <iostream>

export module m3;

#ifndef VERSION
#define VERSION "X.X.X"
#endif

export void greetings_plus();

module :private;

//export void greetings() { //error: export declaration cannot be used in a private module fragment
void greetings() {
	std::cout << "Greetings!\n";
}

void version() {
	std::cout << "VERSION = " << VERSION << std::endl;
}

void greetings_plus() {
	greetings();
	version();
}
