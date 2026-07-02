#include "h1.h"
#include "h2.h"
#include "h3.h"

// Signal: 11 (SEGV) expected!
int main(int, const char **) {
	S1 s1;
	return 0;
}