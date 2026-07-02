// Macro definitions in modules are not exported
module;

#include <iostream>

#define CONST1 1

export module m3;

#define CONST2 2

// Macro definitions from importing unis are not defined
#ifndef CONST0
#warning "CONST0 is not defined in module m3"
#endif

#ifdef CONST1
#warning "CONST1 is defined in m3"
#endif
#ifdef CONST2
#warning "CONST2 is defined in m3"
#endif

// Command line macros are always processed
#ifndef VERSION
#define VERSION "X.X.X"
#endif


void greetings() {
	std::cout << "Greetings!\n";
}

void version() {
	std::cout << "VERSION = " << VERSION << std::endl;
}

export
void greetings_plus() {
	greetings();
	version();
}
