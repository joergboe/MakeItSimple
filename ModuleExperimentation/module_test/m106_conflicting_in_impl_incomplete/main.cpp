#include <iostream>

import mod1;

int main(int, const char**) {
	std::cout << "Hello!\n";
	X::f(nullptr);
	X::g(nullptr);
	X::A a; //error: aggregate ‘X::A@mod1 a’ has incomplete type and cannot be defined
	return 0;
}
