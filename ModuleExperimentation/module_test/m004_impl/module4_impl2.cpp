// Pure module implementation units are translated into objects files and no
// cmi file will be generated.

module; // global module fragment

#include <iostream>
#include <vector>
#include <numeric>

module m4; // module declaration not exported

void getProduct(const std::vector<int>& vec) {
	std::cout << "Product = " << std::accumulate(vec.begin(), vec.end(), 1, std::multiplies<int>()) << std::endl;
}