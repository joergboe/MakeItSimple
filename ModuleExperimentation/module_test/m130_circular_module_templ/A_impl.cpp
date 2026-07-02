export module A_impl;

export template<typename B>
struct A_impl {
	B* v;
	void f(B* b) {
		v = b;
	}
};
