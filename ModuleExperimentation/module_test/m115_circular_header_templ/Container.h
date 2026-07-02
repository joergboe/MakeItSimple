#ifndef _TEMPL_H_
#define _TEMPL_H_

template<typename T>
struct Container {
	// variant 1: can be built
	T * val;
	Container() : val(new T) {}
	// variant 2: error: ‘Container<T>::val’ has incomplete type
	//T val;
	//Container() : val() {}
};

#endif