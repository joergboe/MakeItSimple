export module Cyclic:A;

class B;
export class A {
public:
	char name() { return 'A'; }
	void f(B& b);
};
