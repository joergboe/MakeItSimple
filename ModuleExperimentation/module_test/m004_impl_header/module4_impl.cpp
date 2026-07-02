// Pure module implementation units are translated into objects files and no
// cmi file will be generated.

module; // global module fragment

#include "header1.h"

module m4; // module declaration not exported

import <iostream>;
import <vector>;
import <numeric>;

void greetings() {
	std::cout << "Greetings!\n";
}

void version() {
	std::cout << "VERSION = " << VERSION << std::endl;
}

void getProduct(const std::vector<int>& vec) {
	std::cout << "Product = " << std::accumulate(vec.begin(), vec.end(), 1, std::multiplies<int>()) << std::endl;
}