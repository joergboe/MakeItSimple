module math:math1;

import :commons;

int add(int fir, int sec) {
	return fir + sec;
}

float get_pi() {
	/* All definitions and declarations in a module partition are visible by the importing module unit,
	 * whether exported or not. */
	return my_pi;
}
