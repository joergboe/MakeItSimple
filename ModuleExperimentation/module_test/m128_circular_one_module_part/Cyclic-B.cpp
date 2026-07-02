export module Cyclic:B;

class A;
export class B {
public:
	char name() { return 'B'; }
	void f(A& a);
};
