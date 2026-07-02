export module module2;

import "header2.h";

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
