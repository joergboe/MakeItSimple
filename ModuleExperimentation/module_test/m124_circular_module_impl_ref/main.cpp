import m1;

// No circular dep but ambiguous forward declaration
// ‘struct S2@m2’ vs. ‘struct S2@m1’
int main(int, const char **) {
	S1 s1;
	return 0;
}