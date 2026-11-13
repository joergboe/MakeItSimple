# --------------------------------------------------------------------------

# *** Structure of the depfile file (%.dep) ***
# The depfile lists the header dependencies of an Header Unit and is generated with disabled
# auto inclusion.
# (1) absolute header file name
system/iostream.dep: /usr/include/c++/16/iostream /usr/include/stdc-predef.h ...
# (2) relative header file name
system/header2.h.dep: header2.h /usr/include/stdc-predef.h /usr/include/c++/16/cstddef ...

# *** Structure of header unit database (header-unit.dep) ***
# Contains a variable with the (module) information of each Header Unit to translate:
# CXX_KIND_UNIT_SRC_MOD_CMI_LIST += <kind>;<unit name>;<source name>;<logical module>;<cmi name>
CXX_KIND_UNIT_SRC_MOD_CMI_LIST += system;cstddef;/usr/include/c++/16/cstddef;/usr/include/c++/16/cstddef;gcm.cache/./usr/include/c++/16/cstddef.gcm
CXX_KIND_UNIT_SRC_MOD_CMI_LIST += system;iostream;/usr/include/c++/16/iostream;/usr/include/c++/16/iostream;gcm.cache/./usr/include/c++/16/iostream.gcm

CXX_KIND_UNIT_SRC_MOD_CMI_LIST += user;header2.h;header2.h;./header2.h;gcm.cache/,/header2.h.gcm

# *** Structure of header unit map (header-map.modm) ***
# The module map for gcc lists:
# <module name> <cmi file name>

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

$root gcm.cache
/usr/include/c++/16/cstddef ./usr/include/c++/16/cstddef.gcm
/usr/include/c++/16/iostream ./usr/include/c++/16/iostream.gcm
./header2.h ,/header2.h.gcm

# *** Structure of header module depfiles (%.m.dep) ***
# (1) absolute header file name
gcm.cache/./usr/include/c++/16/iostream.gcm : gcm.cache/./usr/include/c++/16/cstdio.gcm gcm.cache/./usr/include/c++/16/cstddef.gcm
# (2) relative header file name
gcm.cache/,/header2.h.gcm : gcm.cache/./usr/include/c++/16/cstddef.gcm

# *** Structure of header part of module map to be used by the main script (module-map-h.txt) ***
/usr/include/c++/16/cstddef ./usr/include/c++/16/cstddef.gcm
/usr/include/c++/16/iostream ./usr/include/c++/16/iostream.gcm
./header2.h ,/header2.h.gcm


# *** Structure of information file (%.depn) ***
# The information file contains the header unit to source and cmi file mapping CXX_UNIT_SRC_MOD_CMI_KIND_LIST.
# (1) relative header file name
CXX_UNIT_SRC_MOD_CMI_KIND_LIST += header.h;header.h;./header.h;gcm.cache/,/header.h.gcm;user
# (2) absolute header file name
CXX_UNIT_SRC_MOD_CMI_KIND_LIST += iostream;/usr/.../iostream;/usr/.../iostream;gcm.cache/./usr/.../iostream.gcm;system

# *** Structure of dependency file (%.dep) ***
# The dependency file contains the dependency tree for all header unit cmi files.
# (1) The first rule contains the pure header dependencies.
header.h.dep: header.h /usr/include/stdc-predef.h /usr/include/c++/16/cstddef ...
# (2) If the header unit list contains one of the dependencies, a second rule is appended where the header dependency
# is replaced by the cmi file.
gcm.cache/,/header.h.gcm : gcm.cache/./usr/include/c++/16/cstddef.gcm ...