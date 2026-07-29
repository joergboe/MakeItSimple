module;

#include <vector>
#include <numeric>

module mäthæ:implementation;

int getProduct(const std::vector<int>& vec) {
	return std::accumulate(vec.begin(), vec.end(), 1, std::multiplies<int>());
}

int add(int fir, int sec) {
	return fir + sec;
}

const char greeting_string[] = "Hello Module Partitions!\n";
