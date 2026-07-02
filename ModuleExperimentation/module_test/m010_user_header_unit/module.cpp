#include "headers/module.h"

#ifndef CONST1
#warning "Macros from importing units are not visible CONST1"
#endif

const char another_string[]="Some other string";

const char * greeting() {
	return "Greetings!";
}

const char * version() {
	return VERSION;
}
