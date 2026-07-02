export module B_impl;

export template<typename T>
struct Struct_B_impl {
	T* v;
	void f(T* b) {
		v = b;
	}
};
