export module A_impl;

export template<typename T>
struct Struct_A_impl {
	T* v;
	void f(T* b) {
		v = b;
	}
};
