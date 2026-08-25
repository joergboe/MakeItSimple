# The rules for the example with header units
# Module dependencies expressed in generated rules.
# With automatic dependency generation using the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST schema.
# Use a separate makefile for production goals.

MAKEFLAGS += -r

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) $(this_makefile) with goals $(MAKECMDGOALS))

# default target
my_program :

# project definitions
include project.mk

# export variables required in other makefiles
export SOURCES
export CXX_SYSTEM_HEADER_UNITS
export CXX_USER_HEADER_UNITS

# trigger dependent targets
FORCE :: ;

# make header unit cmi files - must run every time
header-map-system ::
	$(MAKE) -f Makefile6-auto-headers.mk KIND=SYSTEM $@
	@echo

# make header unit cmi files - must run every time
header-map-user : FORCE | header-map-system
	$(MAKE) -f Makefile6-auto-headers.mk KIND=USER $@
	@echo

# make all depfiles
depfiles ::= $(SOURCES:.cpp=.dep)
.PHONY : depend
depend : | header-map-user
	$(MAKE) -f Makefile6-auto-all.mk $(depfiles)
	@echo

# This rule must run even if the target exists
# NOTE: There is no way to make a pattern rule with no prerequisites to run even when the target exists.
# So we need a prerequisite that is always out of date
# If a list of explicit rules is used that requires that we must know all possible targets
# In case of module cmi files this requires a sucessful module scan.
#%: header-map-system
#	$(MAKE) -f Makefile6-auto-all.mk $@
#	@echo

# all pattern rules shall be terminal rules
# all pattern rules must run even if the target exists
# system header unit
gcm.cache/./% :: FORCE
	$(MAKE) -f Makefile6-auto-headers.mk KIND=SYSTEM $@
	@echo

# user header unit
gcm.cache/,/% :: FORCE | header-map-system
	$(MAKE) -f Makefile6-auto-headers.mk KIND=USER $@
	@echo

# my_program $(objects) $(depfiles)
% :: FORCE | header-map-user
	$(MAKE) -f Makefile6-auto-all.mk $@
	@echo

# cleanup
objects ::= $(SOURCES:.cpp=.o)
depfiles_p1689 ::= $(SOURCES:.cpp=.ddi)
#deptempfiles ::= $(addsuffix ~,$(depfiles))

.PHONY : clean
clean :
	rm -f my_program
	rm -f $(objects)
	rm -fv gcm.cache/*.gcm
	rm -f $(depfiles)
	rm -f $(depfiles_p1689)
#	rm -f $(deptempfiles)
	@echo

.PHONY : clean-header-units
clean-header-units : clean-user-header-units clean-system-header-units

user_unit_mapfiles ::= $(addsuffix .map,$(CXX_USER_HEADER_UNITS))
user_unit_infofiles ::= $(addsuffix .dep,$(CXX_USER_HEADER_UNITS))
user_unit_depfiles ::= $(addsuffix .d,$(CXX_USER_HEADER_UNITS))
user_unit_p1689files ::= $(addsuffix .ddi,$(CXX_USER_HEADER_UNITS))
user_unit_p1689files2 ::= $(addsuffix .ddi2,$(CXX_USER_HEADER_UNITS))
user_unit_tmpfiles ::= $(addsuffix ~,$(user_unit_infofiles))

.PHONY : clean-user-header-units
clean-user-header-units :
	rm -f header-map-user
	rm -rfv 'gcm.cache/,'
	rm -f $(user_unit_mapfiles)
	rm -f $(user_unit_infofiles)
	rm -f $(user_unit_depfiles)
	rm -f $(user_unit_tmpfiles)
	rm -f $(user_unit_p1689files)
	rm -f $(user_unit_p1689files2)
	@echo

sys_unit_mapfiles ::= $(addsuffix .map,$(CXX_SYSTEM_HEADER_UNITS))
sys_unit_infofiles ::= $(addsuffix .dep,$(CXX_SYSTEM_HEADER_UNITS))
sys_unit_depfiles ::= $(addsuffix .d,$(CXX_SYSTEM_HEADER_UNITS))
sys_unit_p1689files ::= $(addsuffix .ddi,$(CXX_SYSTEM_HEADER_UNITS))
sys_unit_p1689files2 ::= $(addsuffix .ddi2,$(CXX_SYSTEM_HEADER_UNITS))
sys_unit_tmpfiles ::= $(addsuffix ~,$(sys_unit_infofiles))

.PHONY : clean-system-header-units
clean-system-header-units :
	rm -f header-map-system
	LIST=(); for x in gcm.cache/*; do if [[ -d $${x} && $${x} != 'gcm.cache/,' ]]; then LIST+=("$${x}"); fi; done; rm -rfv "$${LIST[@]}";
	rm -f $(sys_unit_mapfiles)
	rm -f $(sys_unit_infofiles)
	rm -f $(sys_unit_depfiles)
	rm -f $(sys_unit_tmpfiles)
	rm -f $(sys_unit_p1689files)
	rm -f $(sys_unit_p1689files2)
	@echo

.PHONY : purge
purge : clean clean-header-units
	rm -fv *.d *.dep *.dep~ *.ddi *.ddi2 *.map *.o
	rm -fv stored-system-units stored-system-units-config stored-system-units-config~
	rm -fv stored-user-units stored-user-units-config stored-user-units-config~
#	rm -f module-cmi-list sys-unit-cmi-list user-unit-cmi-list
	rm -rfv gcm.cache
	@echo


# prevent pattern rules for this targets
Makefile6-auto.mk : ;
project.mk : ;
