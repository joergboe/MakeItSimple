# Makefile translates System Header Units and User Header Units
#
# This script requires two variables with the list of header units to translate
# CXX_SYSTEM_HEADER_UNITS and CXX_USER_HEADER_UNITS.
#
# Stage 1 determines the header unit to source and cmi file mapping. This rule fires only once at start-up or after a
# configuration change. (The infofiles '%.depn' contain the variable CXX_UNIT_SRC_MOD_CMI_KIND_LIST)
#
# Stage 2 generates a module mapper file for the header units. (header-mapper.txt)
#
# Stage 3 determines the dependency tree for all header unit cmi files. A script scans the dependencies of a header unit
# (the first rule). If a particular dependency exists in the system header or user header database, a rule with the
# dependent cmi file is added. (depfiles '%.dep') This ensures that make builds the header units in the appropriate
# order.
#
# Stage 4 translates header unit source files to cmi files. The depfile substitutes all header dependencies of the
# cmi file.
#
# Stage 5 make a final cmi files list. ('header-cmis.txt')
#
# Relative header file locations are considered relative to the current directory.
#
# Intermediate build artifacts are stored in directories 'system' and 'user'.
# The files 'header-units-list', 'header-units-config', 'header-mapper.txt' and 'header-cmis.txt' are stored in
# current directory.


# Delete the stored Header Units list if the list has changed at start up.
units ::= $(CXX_SYSTEM_HEADER_UNITS) $(CXX_USER_HEADER_UNITS)
ifneq ($(units),$(old_units))
  $(shell rm -f header-units-list)
endif

# A missing file triggers this rule.
header-units-list :
	mv header-units-list.temp $@

# Delete the stored configuration file if the configuration has changed at start up.
configuration ::= $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
ifneq ($(configuration),$(old_configuration))
  $(shell rm -f header-units-config)
endif

# A missing configuration file triggers this rule.
header-units-config :
	mv header-units-config.temp $@

# Stage 1: Generate infofiles.
# The source file name is figured out from script get-header-info-and-map.sh and the cmi file name is constructed.
# Output : CXX_UNIT_SRC_MOD_CMI_KIND_LIST
# Source file may be relative to the current directory or absolute.
infofiles_sys ::= $(addsuffix .depn,$(CXX_SYSTEM_HEADER_UNITS))
$(infofiles_sys) : %.depn: header-units-list header-units-config
	g++ -x c++-system-header $* -c -MM -MF $*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	get-header-info-and-map.sh $*.dep.0 $@ $* $(CXX_MODULE_CACHE) gcm system # provide variable CXX_UNIT_SRC_CMI_LIST

infofiles_user ::= $(addsuffix .depn,$(CXX_USER_HEADER_UNITS))
$(infofiles_user) : %.depn: header-units-list header-units-config
	g++ -x c++-user-header $* -c -MM -MF $*.dep.0 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	get-header-info-and-map.sh $*.dep.0 $@ $* $(CXX_MODULE_CACHE) gcm user # provide variable CXX_UNIT_SRC_CMI_LIST

# Stage 2: Generate database cmi mapper: <logical name> <cmi>
header-mapper.txt : $(infofiles_sys) $(infofiles_user)
	# concatenate logical name and cmi file name of all infofiles to header-mapper.txt

# Stage 3: Generate the depfiles
depfiles_sys ::= $(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS))
$(depfiles_sys) : %.dep : header-mapper.txt
	g++ -x c++-system-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$*.o -fdeps-file=$*.ddi \
 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	add-header-module-dep.sh header-mapper.txt $(CURDIR) $@.1 $@

depfiles_user ::= $(addsuffix .dep,$(CXX_USER_HEADER_UNITS))
$(depfiles_user) : %.dep : header-mapper.txt
	g++ -x c++-user-header $* -c -M -MF $@.1 -MQ $@ -MP -fdeps-format=p1689r5 -fdeps-target=$*.o -fdeps-file=$*.ddi \
 $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
	add-header-module-dep.sh header-mapper.txt $(CURDIR) $@.1 $@

# Stage 4: cmi file generation
# rule template for unit cmi file targets
# automatic header inclusion is effective
define cmi_file_rule
  $(cmi) : $(src) $(unit).dep
	g++ -x c++-$(kind)-header $(unit) -c -fmodule-mapper=header-mapper.txt $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH)
endef

# include information about source names CXX_UNIT_SRC_MOD_CMI_KIND_LIST
include $(infofiles_sys) $(infofiles_user)

# evaluate information from infofiles and generate:
# rules for unit cmi files
# a cmi files list
cmifiles ::=
$(foreach line,$(CXX_UNIT_SRC_MOD_CMI_KIND_LIST),\
  $(let unit src mod cmi kind,$(subst ;, ,$(line)),\
      $(eval cmifiles += $(cmi))\
      $(eval $(cmi_file_rule))\
  )\
)
# include the depfile rules
include $(depfiles_sys) $(depfiles_user)

# Stage 5: Make a final list of cmi file names.
header-cmis.txt : $(cmifiles)
	@for x in $^; do echo "$$x"; done > $@
# --------------------------------------------------------------------------

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
