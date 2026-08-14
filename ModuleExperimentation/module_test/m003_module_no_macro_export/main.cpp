// Macro definitions are not available in imported modules.
#define MAIN0 0

import m3;

#ifdef MAIN0
#warning "MAIN0 is defined in main"
#endif

// Macro definitions in modules are not exported
#ifndef CONST1
#warning "CONST1 is no defined in main"
#endif
#ifndef CONST2
#warning "CONST2 is no defined in main"
#endif

int main(int, const char**) {
	greetings_plus();
	return 0;
}
