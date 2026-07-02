import m1;
import m2;

// make: Circular gcm.cache/m1.gcm <- gcm.cache/m2.gcm dependency dropped.
// Build error: m2: error: failed to read compiled module: No such file or directory
int main() {
	S1 s1;
	return 0;
}