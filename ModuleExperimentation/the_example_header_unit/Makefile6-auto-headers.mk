# This makefile generates cmi files for header units with automatic dependency generation
# and uses the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST schema.
# Each header unit is translated independently and auto import is disabled.

# With variable KIND=SYSTEM system header units are build and the names are expected in variable CXX_SYSTEM_HEADER_UNITS
# With variable KIND=USER user header units are build and the names are expected in variable CXX_USER_HEADER_UNITS

# The first step generates the 'infofiles' with information module name and source name.
# For header units the module name depends only on the storage location and the header file name, thus the
# 'infofiles' depend only on the configuration (CPPFLAGS with include path..) and the header list.

# After completion of the first step make potentially re-starts the script and step 2 is executed.

# The second step builds all cmi files and the dependency files are generated as by product and follows the rules
# of the classical dependency generation for C/C++ sources.
# See: https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/
# The rules for the cmi files are generated from the CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST list.
# Every cmi file is generated with an individual module map file with one entry.
# So there are no mutual cmi file dependencies.

# Required: p1689_to_mk.sh -d

this_makefile ::= $(lastword $(MAKEFILE_LIST))

$(info )
$(info **** $(if $(MAKE_RESTARTS),Restart # $(MAKE_RESTARTS),Start) $(this_makefile) with kind $(KIND) goals $(MAKECMDGOALS))

# Default target must come first
header-map-$(kind) :

ifeq ($(KIND),SYSTEM)
  kind ::= system
else ifeq ($(KIND),USER)
  kind ::=user
else
  $(error Invalid KIND)
endif

# macro to display information
due_to = @echo 'Run target $@ - Due to $?'

# check whether the units config has changed
ifndef MAKE_RESTARTS
  $(file > stored-$(kind)-units-config~,$(CPPFLAGS)) # store configuration here to avoid shell quoting issues
  $(info $(shell\
    if diff stored-$(kind)-units-config stored-$(kind)-units-config~; then\
      echo "No changes in $(kind) units configuration.";\
    else\
      rm stored-$(kind)-units-config; echo "!$(KIND) units configuration has changed!";\
    fi))
endif

# missing configuration file triggers this rule
stored-$(kind)-units-config :
	$(due_to)
	mv stored-$(kind)-units-config~ $@
	@echo

# check whether the units list has changed
ifndef MAKE_RESTARTS
  old_units ::= $(file < stored-$(kind)-units)
  ifneq ($(CXX_$(KIND)_HEADER_UNITS),$(old_units))
    $(info !$(KIND) units list has changed!)
    $(shell $(RM) stored-$(kind)-units) # trigger rule stored-$(kind)-units and store the current unit list
  else
    $(info No changes in $(kind) units list.)
  endif
endif

$(info Registered $(kind) units: $(CXX_$(KIND)_HEADER_UNITS))

# If the list of header unit is changed, clean all cmi-files to avoid out dated files in cmi cache.
stored-$(kind)-units :
	$(due_to)
	echo '$(CXX_$(KIND)_HEADER_UNITS)' > $@
	$(MAKE) -f Makefile6-auto.mk clean-$(kind)-header-units
	@echo

# generate infofiles with module information and source file names
infofiles ::= $(addsuffix .dep,$(CXX_$(KIND)_HEADER_UNITS))
$(infofiles) : %.dep: stored-$(kind)-units stored-$(kind)-units-config
	$(due_to)
	g++ -x c++-$(kind)-header $* -c -std=c++20 -fmodules -MM -MF $@ -fdeps-format=p1689r5 -fdeps-target=$*.o -fdeps-file=$*.ddi
	./p1689_to_mk.sh -d $*.ddi $@ $* $*.o
	@echo

# include module info source file names from infofiles
CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST ::=
include $(infofiles)

comma ::= ,
empty ::=
space ::= $(empty) $(empty)

# repl - replace: '.' by ',' and '..' by ',,'
# input: dir - path component
repl = $(if $(subst ..,,$(dir)),$(if $(subst .,,$(dir)),$(dir),$(comma)),$(comma)$(comma))

# rheader2cmi - converts a relative header name to the file name in gcm cache according to the gcc rules
# input: mod - the header name starting with ./
rheader2cmi = gcm.cache/$(subst $(space),/,$(foreach dir,$(subst /, ,$(mod)),$(repl))).gcm

# mod2cmi - expands to the cmi-file-name for a given module-name
# input: mod - the module/header name
mod2cmi = $(if $(patsubst /%,,$(mod)),$(if $(patsubst ./%,,),gcm.cache/$(mod).gcm,$(rheader2cmi)),gcm.cache$(mod).gcm)

# rule template for unit cmi file targets
# Each unit has a individual module map, thus automatic header inclusion is effectively disabled.
define cmi_file_rule
  $(info generate $(unit) rule : $(mod2cmi) : $(src) $(unit).d $(unit).map)

  $(mod2cmi) : $(src) $(unit).d $(unit).map
	$$(due_to)
	g++ -x c++-$(kind)-header $(unit) -c -std=c++20 -fmodules -MMD -MQ $$@ -MP -MF $(unit).d -fdeps-format=p1689r5 -fdeps-target=$(obj) -fdeps-file=$(unit).ddi2 -fmodule-mapper=$(unit).map
	touch $$@
	@echo
endef

# rule for individual unit map file targets
define unit_map_rule
  $(info generate $(unit) map rule : $(unit).map : $(unit).dep)

  $(unit).map : $(unit).dep
	$$(due_to)
	echo "$(mod) $(mod2cmi)" > $(unit).map
	@echo
endef

# evaluate information from 'infofiles' and generate:
# rules for unit cmi files
# rules for individual unit map files
# a cmi files list
# the global header map
cmifiles ::=
header_map ::=
ifndef CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST
  $(info No rules to build.)
endif
$(foreach line,$(CXX_UNIT_OBJ_SRC_MOD_IF_REQ_LIST),\
	$(let unit obj src mod is_if reqs,$(subst ;, ,$(line)),\
		$(if $(subst -,,$(mod)),\
			$(eval cmifiles += $(mod2cmi))\
			$(eval header_map ::= $$(header_map)$$(mod) $$(mod2cmi)\n)\
			$(eval $(cmi_file_rule))\
			$(eval $(unit_map_rule))\
		,\
			$(warning $(kind) interface unit with no logical name in unit $(unit) !)\
		)\
	)\
)

#$(info cmifiles = '$(cmifiles)')

# classical dependency information
depfiles ::= $(addsuffix .d,$(CXX_$(KIND)_HEADER_UNITS))

# PHONY rules for depfiles - trigger the cmi file rule if depfile is missing
$(depfiles) : %.d : ;

# include depfiles if available
include $(wildcard $(depfiles))

# generate system header map
header-map-$(kind) : $(cmifiles)
	$(due_to)
	@echo -en '$(header_map)' > $@
	@echo -e '$(KIND) units complete.\n'

$(info **** End reading makefile $(this_makefile))
$(info )
