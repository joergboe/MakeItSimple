export module m2;

// One can use macros in modules and from included header files.
#include "header2.h"

export
const char * greetings() {
	return "Greetings!";
}

export
const char * version() {
	return VERSION;
}
