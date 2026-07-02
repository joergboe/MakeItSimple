export module m1;

#ifndef VERSION
#	define VERSION "X.X.X"
#endif

export
const char * greetings() {
	return "Greetings! VERSION=" VERSION;
}
