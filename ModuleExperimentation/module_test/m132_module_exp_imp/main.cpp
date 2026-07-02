import A;

struct S {
	void f() {}
};

int main() {
	S s;
	s.g(); // error: redeclaring ‘struct S@A_sub’ in global module conflicts with import
	return 0;
}
