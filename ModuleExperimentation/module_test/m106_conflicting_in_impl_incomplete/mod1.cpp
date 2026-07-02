export module mod1;

export namespace X {
	struct A;	//export of a incomplete type
	
	void f(A*);
	void g(A*);
}
