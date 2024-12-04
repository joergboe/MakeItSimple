extern "C" {
	#include "m2.h"

	void greetings();
}

#include <iostream>

#ifndef MYHELLO
#define MYHELLO "Alternative Hello!"
#endif

using namespace std;

int main() {
	cout << "Hello World Program m1 !!!" << endl;
	hellom2();
	greetings();
	cout << MYHELLO << endl;
#	ifdef MYHELLO2
	cout << MYHELLO2 << endl;
#	endif
	return 0;
}
