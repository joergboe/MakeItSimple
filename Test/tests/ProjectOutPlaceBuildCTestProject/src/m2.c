#include "m2.h"
#include "defines/definitions.h"
#include "internal_definitions.h"

#include <stdio.h>

void hellom2(void) {
	for (int i = 0; i < maxcount; ++i) {
		printf("Hello World Program m2 !!!\n");
	}
	printf("%d\n", A_CONST);
	return;
}
