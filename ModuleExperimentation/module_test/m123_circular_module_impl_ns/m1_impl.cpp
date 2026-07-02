module;

#include <iostream>

module m1;
import m2;

namespace ns {
	S1::S1() : v() {
		std::cout << "S1::S1()\n";
	};
}
