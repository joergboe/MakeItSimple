import m1;
import m2;

int main(int, const char **) {
	ns::S1 s1;
	ns::S2 s2;
	s1.v = &s2; // error: cannot convert ‘ns::S2@m2*’ to ‘ns::S2@m1*’ in assignment
	return 0;
}