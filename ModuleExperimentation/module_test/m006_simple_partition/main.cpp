/*
 * Module with simple partitions
 */

#include <iostream>

/*
 * Module partition units are visible only from inside the named module
 * Translation units outside the named module cannot import a module partition directly).
 */
//import math:math1; //error: expected ‘;’ before ‘:’ token
//import math:math2; //error: expected ‘;’ before ‘:’ token

import math;

int main() {
	std::cout << "add(3, 4): " << add(3, 4) << std::endl;
	std::cout << "mul(3, 4): " << mul(3, 4) << std::endl;
	std::cout << "pi: " << get_pi() << std::endl;
	// Not exported definitions visible in math only.
	//float x = my_pi; //error: ‘my_pi’ was not declared in this scope
}
