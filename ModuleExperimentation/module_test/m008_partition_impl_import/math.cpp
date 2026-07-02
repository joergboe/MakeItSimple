export module math;

/* It is not recommended to import implementation partitions in interface partitions or module interfaces */
/* clang warns: */
//import :commons; //warning: importing an implementation partition unit in a module interface is not recommended.
//Names from math:commons may not be reachable [-Wimport-implementation-partition-unit-in-interface-unit]


export int add(int fir, int sec);
export float get_pi();

export int mul(int fir, int sec);
export float circumference(float radius);
