module;

#include "header2.h"

export module module$2;

export
float sum(float a, float b) {
	return a + b;
}

export
float square(float a) {
	return a * a;
}

export
float circumference(float r) {
	return r * 2 * PI;
}
