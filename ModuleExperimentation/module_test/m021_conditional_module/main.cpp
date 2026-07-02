#ifndef VARIANT_B
import m1;
#else
import m2;
#endif

#ifndef GREETING
#warning "Macro GREETING is invisible"
#endif

int main(int, const char **) {
	greetings();
	return 0;
}