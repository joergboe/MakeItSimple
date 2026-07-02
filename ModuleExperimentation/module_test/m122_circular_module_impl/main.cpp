import m1;
import m2;

int main(int, const char **) {
	S1 s1;
	S2 s2;
	s1.v = &s2; // error: cannot convert ‘S2@m2*’ to ‘S2@m1*’ in assignment
	return 0;
}