module;

#include <iostream>

export module lib_A;

// If two declarations of an entity are attached to different modules, the program is ill-formed; no
// diagnostic is required if neither is reachable from the other!
// seems to mean in one TU??
int f() { return 0; } // f has module linkage f@lib_A

export int x = f();   // x equals 0
