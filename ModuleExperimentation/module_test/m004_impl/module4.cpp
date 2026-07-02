module;

#include <vector>
#include <iostream>

export module m4;

export inline void greetings() {
	std::cout << "Greetings!\n";
}

export void version();

export void getProduct(const std::vector<int>&);