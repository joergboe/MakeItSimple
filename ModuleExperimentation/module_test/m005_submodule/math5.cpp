// Submodule

/* The module name consists of one or more identifiers separated by dots (for example:
 * mymodule, mymodule.mysubmodule, mymodule2...).
 * Dots have no intrinsic meaning, however they are used informally to represent hierarchy. 
 *
 * If any identifier in the module name or module partition is defined as an object-like macro,
 * the program is ill-formed.
 */

//#define MOD_NAME math5 math5.cpp:14:8: error: module declaration must occur at the start of the translation unit (clang++)
//export module MOD_NAME; //math5.cpp:12:15: error: module name ‘MOD_NAME’ cannot be an object-like macro

export module math5;

export import math5.sub1;
export import math5.sub2;
