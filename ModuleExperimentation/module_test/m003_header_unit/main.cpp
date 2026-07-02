// Macro definitions are not available in imported modules.
#define CONST0 0

import m3;

#ifdef CONST0
#warning "CONST0 is defined in main"
#endif

// Macro definitions in modules are not exported
#ifndef CONST2
#warning "CONST2 is no defined in main"
#endif

int main(int, const char**) {
	greetings_plus();
	return 0;
}
