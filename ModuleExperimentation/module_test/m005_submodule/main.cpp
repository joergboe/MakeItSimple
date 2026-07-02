#include <iostream>
#include <vector>

import math5;

// Submodules may be imported:
//import math4.sub1;
//import math4.sub2;


int main() {
	std::cout << std::endl;
	std::cout << "math::add(2000, 20): " << add(2000, 20) << std::endl;
	std::vector<int> myVec{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
	std::cout << "math::getProduct(myVec): " << getProduct(myVec) << std::endl;
	std::cout << std::endl;
}
