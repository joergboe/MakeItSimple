module;
#include <iostream>
module mod1;

namespace X {
	struct A {
		float val;
	};

	void f(A*) {
		std::cout << "void f(A*)\n";
	}
}