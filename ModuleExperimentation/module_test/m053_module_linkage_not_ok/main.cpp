import M;

static int h();   // Error: matches #3
int k();          // Error: matches #4

int main() {
	//f(); // error: undefined reference to `f()'
	return 0;
}
