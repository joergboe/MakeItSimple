module m1:impl;

import m2;

struct S1 {
	const S2 &v;
	S1() : v(*new S2) { };;
};
