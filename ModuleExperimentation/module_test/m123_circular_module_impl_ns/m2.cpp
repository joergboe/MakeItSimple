export module m2;

namespace ns {
	struct S1;

	export struct S2 {
		S1 * v;
		S2();
	};
}
