#ifndef _H3_H_
#define _H3_H_

#include "Container.h"

struct S1;

struct S3 {
	Container<S1> v;
	S3();
};

#endif
