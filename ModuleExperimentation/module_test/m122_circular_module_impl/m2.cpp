export module m2;

//export struct S1; //main.cpp:7:9: error: reference to ‘S1’ is ambiguous
struct S1;

export struct S2 {
	S1 * v;
	S2();
};
