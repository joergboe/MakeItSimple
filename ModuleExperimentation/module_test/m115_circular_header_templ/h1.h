#ifndef _H1_H_
#define _H1_H_

#include "Container.h"

struct S2;

struct S1 {
	Container<S2> v;
	S1();
};

#endif
