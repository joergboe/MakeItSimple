extern "C" {
	#include "m2.h"

	void greetings();
}
#include "m3.hpp"

#include <iostream>

#ifndef MYHELLO
#define MYHELLO "Alternative internal: Hello world!!!"
#endif

using namespace std;

int main() {
	cout << "Hello World Program m1 !!!" << endl;
	cout << MYHELLO << endl;
#	ifdef MYHELLO2
	cout << MYHELLO2 << endl;
#	endif
	hellom2();
	hellom3();
	greetings();
	return 0;
}
