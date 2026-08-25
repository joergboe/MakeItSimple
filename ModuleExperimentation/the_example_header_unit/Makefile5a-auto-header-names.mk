# This makefile generates info files for header units and uses the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST schema.

# KIND=SYSTEM : build system header units infofiles are build and the names are expected in variable CXM_SYSTEM_HEADER_UNITS
# KIND=USER user header units infofiles are build and the names are expected in variable CXM_USER_HEADER_UNITS

# Required: dep_2_src.sh

# Rule 1 - update configuration if configuration has changed
# stored-$(kind)-units-config :

# Rule 2 - update the header unit list if changed
# stored-$(kind)-units :

# Rule 3 

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** Start $(this_makefile) with kind $(KIND) goals $(MAKECMDGOALS))

# Default target must come first
header-info-$(kind) :

ifndef KIND
  KIND ::= SYSTEM
endif
ifeq ($(KIND),SYSTEM)
  kind ::= system
else ifeq ($(KIND),USER)
  kind ::=user
else
  $(error Invalid KIND)
endif

# only one phony target is expected
is_cleanup_goal ::= $(filter clean purge,$(MAKECMDGOALS))

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# check whether the units config has changed
ifndef MAKE_RESTARTS
  ifndef is_cleanup_goal
    $(file > stored-$(kind)-units-config~,$(CPPFLAGS)) # store configuration here to avoid shell quoting issues
    $(info $(shell if diff stored-$(kind)-units-config stored-$(kind)-units-config~; then\
        echo "No changes in $(kind) units configuration.";\
      else\
        rm stored-$(kind)-units-config; echo "!$(KIND) units configuration has changed!";\
      fi))
  endif
endif

# missing configuration file triggers this rule
stored-$(kind)-units-config :
	$(due_to)
	mv stored-$(kind)-units-config~ $@
	@echo

# check whether the units list has changed
ifndef MAKE_RESTARTS
  ifndef is_cleanup_goal
    old_units ::= $(file < stored-$(kind)-units)
    ifneq ($(CXX_$(KIND)_HEADER_UNITS),$(old_units))
      $(info !$(KIND) units list has changed!)
      $(shell $(RM) stored-$(kind)-units) # trigger rule stored-$(kind)-units and store the current unit list
    else
      $(info No changes in $(kind) units list.)
    endif
  endif
endif

$(info Registered $(kind) units: $(CXX_$(KIND)_HEADER_UNITS))

# missing file triggers this rule
stored-$(kind)-units :
	$(due_to)
	echo '$(CXX_$(KIND)_HEADER_UNITS)' > $@
	@echo

# generate infofiles - source file name is figured out from script dep_2src.sh
infofiles ::= $(addsuffix .n,$(CXX_$(KIND)_HEADER_UNITS))
depfiles ::= $(addsuffix .n.dep,$(CXX_$(KIND)_HEADER_UNITS))
p1689files ::= $(addsuffix .n.ddi,$(CXX_$(KIND)_HEADER_UNITS))
$(infofiles) : %.n: stored-$(kind)-units stored-$(kind)-units-config
	$(due_to)
	g++ -x c++-$(kind)-header $* -c -std=c++20 -fmodules -MM -MF $*.n.dep
	./dep_2_src.sh $*.n.dep $@ $* # only variable CXX_UNIT_SRC_LIST
	@echo

# link all header infos together
header-info-$(kind) : $(infofiles)
	$(due_to)
	cat $^ > header-info-$(kind)
#	if ! diff header-info-$(kind)_temp header-info-$(kind); then mv header-info-$(kind)_temp header-info-$(kind); fi
	@echo

# Cleanup
.PHONY : clean
clean :
	rm -f header-info-$(kind) #header-info-$(kind)_temp
	rm -f $(infofiles)
	rm -f $(depfiles)
	rm -f $(p1689files)
	@echo

.PHONY : purge
purge : clean
	rm -f stored-$(kind)-units stored-$(kind)-units-config stored-$(kind)-units-config~
	@echo

$(info **** End reading makefile $(this_makefile))
$(info )
