#include "m2.h"
#include "defines/definitions.h"

#include <stdio.h>

void hellom2(void) {
	for (int i = 0; i < maxcount; ++i) {
		puts("Hello World Program m2 !!!");
		fflush(stdout);
	}
#	ifdef HELLOM2
	puts(HELLOM2);
	fflush(stdout);
#	endif
	return;
}
