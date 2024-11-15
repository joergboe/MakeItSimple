#include "m2.h"
#include "defines/definitions.h"
#include "internal_definitions.h"

#include <stdio.h>
#include <stdlib.h>

void hellom2(void) {
	for (int i = 0; i < maxcount; ++i) {
		puts("Hello World Program m2 !!!");
		fflush(stdout);
	}
	printf("%d\n", A_CONST);
	return;
}
