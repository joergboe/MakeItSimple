#include "m2.h"

#include <stdio.h>

#ifndef MYHELLO
#define MYHELLO "Alternative Hello!"
#endif

int main(int argc, char ** argv) {
	printf("Hello World Program m1 !!!\n");
	hellom2();
	printf("%s\n", MYHELLO);
#	ifdef MYHELLO2
	printf("%s\n", MYHELLO2);
#	endif
	return 0;
}
