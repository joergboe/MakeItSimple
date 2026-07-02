
// make: Circular gcm.cache/m1.gcm <- gcm.cache/m2.gcm dependency dropped.
// Build error: m2: error: failed to read compiled module: No such file or directory
int main() {
	return 0;
}