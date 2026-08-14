export module m1;

// One can use macros in modules and from command line option -D.
#ifndef VERSION
#	define VERSION "X.X.X"
#endif

export
const char * greetings() {
	return "Greetings! VERSION=" VERSION;
}
