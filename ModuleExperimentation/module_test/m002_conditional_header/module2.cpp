export module m2;

#ifndef VERSION
#include "header2.h"
#endif

export
const char * greetings() {
	return "Greetings!";
}

export
const char * version() {
	return VERSION;
}
