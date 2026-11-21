# --------------------------------------------------------------------------

# *** Stage 1 ***
# Stage 1 determines the dependency tree for each header unit. A dependency file (depfile) contains
# the (conventional) header dependency tree for a header unit. Target of the dependency tree is the
# dependency file itself. The dependency file for a header unit is generated with disabled auto inclusion.

# Structure of the dependency file (%.dep)
# (1) absolute header file name
system/iostream.dep: /usr/include/c++/16/iostream /usr/include/stdc-predef.h ...
# (2) relative header file name
system/header2.h.dep: header2.h /usr/include/stdc-predef.h /usr/include/c++/16/cstddef ...

# *** Stage 2a ***
# Stage 2a determines the original header file for each header unit based on the dependency tree (the first rule).
# Furthermore, the logical source name and the CIM filename are identified.

# The module name (logical name) is constructed from the source file name:
#     Absolute source file:
#         mod=/usr/include/c++/16/iostream
#         mod=/home/src/sample/../module.h
#     Relative source file:
#         mod=./header2.h
#         mod=./incl/header2.h
#         mod=./incl/../header2.h
#         mod=./../header2.h
# 
# The cmi file name is constructed from the module name. Dot characters in the module name are
# replaced by commas.
#     Absolute source file:
#         cmi=<cache-dir>/.<module-name-repl><cmi-suffix>
#         src=/usr/include/c++/16/iostream    cmi=gcm.cache/./usr/include/c++/16/iostream.gcm
#         src=/home/src/sample/../module.h    cmi=gcm.cache/./home/src/sample/,,/module.h.gcm
#     Relative source file:
#         cmi=<cache-dir>/<module-name-repl><cmi-suffix>
#         src=header2.h          cmi=gcm.cache/,/header2.h.gcm
#         src=incl/../header2.h  cmi=gcm.cache/,/incl/,,/header2.h.gcm
#         src=../header2.h       cmi=gcm.cache/,/,,/header2.h.gcm

# These information are packet into the unit database file (header-unit.dep).
# It contains a variable with the following structure:
# CXX_KIND_UNIT_SRC_MOD_CMI_LIST += <kind>;<unit name>;<source name>;<logical module>;<cmi name>
CXX_KIND_UNIT_SRC_MOD_CMI_LIST += system;cstddef;/usr/include/c++/16/cstddef;/usr/include/c++/16/cstddef;gcm.cache/./usr/include/c++/16/cstddef.gcm
CXX_KIND_UNIT_SRC_MOD_CMI_LIST += system;iostream;/usr/include/c++/16/iostream;/usr/include/c++/16/iostream;gcm.cache/./usr/include/c++/16/iostream.gcm

CXX_KIND_UNIT_SRC_MOD_CMI_LIST += user;header2.h;header2.h;./header2.h;gcm.cache/,/header2.h.gcm

# This list us used from make to generate the rules to translate the header units.

# *** Stage 2b ***
# Stage 2b generates the header map file (header-map.modm) with the structure that GCC requires.
# $root <directory>
# <module name> <cmi file name>

$root gcm.cache
/usr/include/c++/16/cstddef ./usr/include/c++/16/cstddef.gcm
/usr/include/c++/16/iostream ./usr/include/c++/16/iostream.gcm
./header2.h ,/header2.h.gcm

# *** Stage 3 ***
# Stage 3 scans the header dependencies of a header unit (the first rule in the dependency file). If one dependency
# is a known target to in the header unit database, a rule with the dependend cmi file is added to the
# header module dependency file (%.m.dep) in the form.
#        <my-cmi> : <dpendency-cmi1> <dpendency-cmi2>

# Structure of header module depfiles (%.m.dep) ***
# (1) absolute header file name
gcm.cache/./usr/include/c++/16/iostream.gcm : gcm.cache/./usr/include/c++/16/cstdio.gcm gcm.cache/./usr/include/c++/16/cstddef.gcm
# (2) relative header file name
gcm.cache/,/header2.h.gcm : gcm.cache/./usr/include/c++/16/cstddef.gcm

# *** Stage 4 ***
# Stage 4 translates the header units to header CMI files. The Dependency File ('%.dep') substitutes all header
# dependencies of the CMI file.

# *** Stage 5 ***
# Stage 5 contributes the header module map to the module map of the main makefile.
# The first line in header-map.modm is removed.
# Structure of header part of module map to be used by the main script (module-map-h.txt) ***
/usr/include/c++/16/cstddef ./usr/include/c++/16/cstddef.gcm
/usr/include/c++/16/iostream ./usr/include/c++/16/iostream.gcm
./header2.h ,/header2.h.gcm
