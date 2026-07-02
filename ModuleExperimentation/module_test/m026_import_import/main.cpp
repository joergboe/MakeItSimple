// main <- module1 <- module2

import module1;

int main(int, const char**) {
	greeting();
	print_sum(2, 3);
	print_square(5);
	return 0;
}