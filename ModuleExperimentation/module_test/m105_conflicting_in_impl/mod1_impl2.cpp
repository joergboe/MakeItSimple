module;
#include <iostream>
module mod1;

namespace X {
	struct A {
		int val;
	};

	void g(A*) {
		std::cout << "void g(A*)\n";
	}

}
