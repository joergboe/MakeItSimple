module;


#include "decls.h"

export module M;

export using ::f; // OK, does not declare an entity, exports #1
int g();          // Error: matches #2, but attached to M
export int h();   // Error: matches #3: error: redeclaring ‘int h()’ in global module conflicts with import
export int k();   // Error matches #4: error: redeclaring ‘int k()’ in global module conflicts with import
