export module m1;

//export struct S2; //main.cpp:8:9: error: reference to ‘S2’ is ambiguous
struct S2;

export struct S1 {
	S2 * v;
	S1();
};
