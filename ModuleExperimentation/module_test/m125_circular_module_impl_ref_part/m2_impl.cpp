module m2:impl;

import m1;

struct S2 {
	const S1 &v;
	S2() : v(*new S1) { };
};
