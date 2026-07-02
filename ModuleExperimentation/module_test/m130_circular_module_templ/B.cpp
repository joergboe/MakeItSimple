export module B;

import A_impl;

export class B;

typedef A_impl<B> A;

export
struct B {
	A *v;
	void f(A *a) {
		v = a;
	}
};
