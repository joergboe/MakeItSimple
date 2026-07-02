module;

#include <vector>
#include <numeric>

export module math5 .sub2;

export int getProduct(const std::vector<int>& vec) {
	return std::accumulate(vec.begin(), vec.end(), 1, std::multiplies<int>());
}
