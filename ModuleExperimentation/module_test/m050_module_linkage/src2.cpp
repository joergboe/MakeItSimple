export module lib_B;

// If two declarations of an entity are attached to different modules, the program is ill-formed; no
// diagnostic is required if neither is reachable from the other!
// seems to mean in one TU??
int f() { return 1; } // OK, f in lib_A and f in lib_B refer to different entities

export int y = f(); // y equals 1
